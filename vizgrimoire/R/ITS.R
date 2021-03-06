## Copyright (C) 2012, 2013 Bitergia
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details. 
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
##
## This file is a part of the vizGrimoire R package
##  (an R library for the MetricsGrimoire and vizGrimoire systems)
##
## AuxiliaryITS.R
##
## Queries for ITS data analysis
##
## Authors:
##   Jesus M. Gonzalez-Barahona <jgb@bitergia.com>
##   Daniel Izquierdo <dizquierdo@bitergia.com>
##   Alvaro del Castillo <acs@bitergia.com>
##   Luis Cañas-Díaz <lcanas@bitergia.com>
## TODO
# issues table queries should be converted as changes table is done


GetTablesOwnUniqueIdsITS <- function() {
    return ('changes c, people_upeople pup')
}

GetFiltersOwnUniqueIdsITS <- function () {
    return ('pup.people_id = c.changed_by') 
}

GetEvolMetricsITS <- function (fields, period, startdate, enddate, filters='') {    
    tables = GetTablesOwnUniqueIdsITS()
    idfilters = GetFiltersOwnUniqueIdsITS()
    if (filters!='') idfilters = paste(idfilters,'AND',filters)
    q <- GetSQLPeriod(period,'changed_on', fields, tables, idfilters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)	
}

GetEvolClosed <- function (closed_condition, period, startdate, enddate) {
    fields = 'COUNT(DISTINCT(issue_id)) AS closed, 
              COUNT(DISTINCT(pup.upeople_id)) as closers'    
    return (GetEvolMetricsITS(fields, period, startdate, enddate, closed_condition));    
}

GetEvolChanged <- function (period, startdate, enddate) {
    fields = 'COUNT(DISTINCT(issue_id)) AS changed, 
              COUNT(DISTINCT(pup.upeople_id)) as changers'
    return (GetEvolMetricsITS(fields, period, startdate, enddate));    
}

GetEvolOpened<- function (period, startdate, enddate) {
    fields = 'COUNT(DISTINCT(id)) AS opened, 
              COUNT(DISTINCT(pup.upeople_id)) as openers'
    tables = "issues i, people_upeople pup"
    filters = "pup.people_id = i.submitted_by"
    q <- GetSQLPeriod(period,'submitted_on', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)	
}

GetEvolReposITS <- function(period, startdate, enddate) {
    fields = 'COUNT(DISTINCT(tracker_id)) AS repositories'
    tables = 'issues'
    filters = ''
    q <- GetSQLPeriod(period,'submitted_on', fields, tables, filters, 
            startdate, enddate)    
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetTablesCompaniesITS <- function (i_db) {
    tables = GetTablesOwnUniqueIdsITS()
    tables = paste(tables,',',i_db,'.upeople_companies upc',sep='')    
}

GetTablesCountriesITS <- function (i_db) {
    tables = GetTablesOwnUniqueIdsITS()
    tables = paste(tables,',',i_db,'.upeople_countries upc',sep='')    
}

GetFiltersCompaniesITS <- function () {
    filters = GetFiltersOwnUniqueIdsITS()
    filters = paste(filters,"AND pup.upeople_id = upc.upeople_id 
                    AND changed_on >= upc.init AND changed_on < upc.end")
}

GetFiltersCountriesITS <- function () {
    filters = GetFiltersOwnUniqueIdsITS()
    filters = paste(filters,"AND pup.upeople_id = upc.upeople_id")
}

GetEvolCompaniesITS <- function(period, startdate, enddate, identities_db) {
    fields = 'COUNT(DISTINCT(upc.company_id)) AS companies'
    tables = GetTablesCompaniesITS(identities_db)
    filters = GetFiltersCompaniesITS()
    q <- GetSQLPeriod(period,'changed_on', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetEvolCountriesITS <- function(period, startdate, enddate, identities_db) {
    fields = 'COUNT(DISTINCT(upc.country_id)) AS countries'
    tables = GetTablesCountriesITS(identities_db)
    filters = GetFiltersCountriesITS()
    q <- GetSQLPeriod(period,'changed_on', fields, tables, filters, 
            startdate, enddate)    
    query <- new ("Query", sql = q)    
    data <- run(query)
    return (data)
}

GetTablesReposITS <- function () {
    return (paste(GetTablesOwnUniqueIdsITS(),",issues,trackers"))
}

GetFiltersReposITS <- function () {
    filters = paste(GetFiltersOwnUniqueIdsITS(),
            "AND c.issue_id = issues.id AND issues.tracker_id = trackers.id")    
    return(filters)    
}

GetEvolReposITS <- function(period, startdate, enddate) {        
    fields = 'COUNT(DISTINCT(trackers.url)) AS repositories'
    tables= GetTablesReposITS()
    filters = GetFiltersReposITS()

    q <- GetSQLPeriod(period,'changed_on', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetStaticITS <- function (closed_condition, startdate, enddate) {
    
    fields = "COUNT(*) as tickets,
              COUNT(*) as opened,
              COUNT(distinct(pup.upeople_id)) as openers,
              DATE_FORMAT (min(submitted_on), '%Y-%m-%d') as first_date,
              DATE_FORMAT (max(submitted_on), '%Y-%m-%d') as last_date"
    tables = 'issues, people_upeople pup'
    filters = 'issues.submitted_by = pup.people_id'
    q = GetSQLGlobal('submitted_on',fields,tables, filters, startdate, enddate)
    
    query <- new ("Query", sql = q)
    data <- run(query)
	
    fields = 'COUNT(DISTINCT(pup.upeople_id)) as closers,
              COUNT(DISTINCT(issue_id)) as closed'
    tables = GetTablesOwnUniqueIdsITS()
    filters = paste(GetFiltersOwnUniqueIdsITS(),"AND",closed_condition)
    q = GetSQLGlobal('changed_on',fields,tables, filters, startdate, enddate)    
    query <- new ("Query", sql = q)
    data1 <- run(query)
    
    fields = 'COUNT(DISTINCT(pup.upeople_id)) as changers,
              COUNT(DISTINCT(issue_id)) as changed'
    tables = GetTablesOwnUniqueIdsITS()
    filters = paste(GetFiltersOwnUniqueIdsITS())
    q = GetSQLGlobal('changed_on',fields,tables, filters, startdate, enddate)    
    query <- new ("Query", sql = q)
    data2 <- run(query)
    
    q <- paste ("SELECT url, name as type FROM trackers t JOIN 
                 supported_trackers s ON t.type = s.id limit 1")	
    query <- new ("Query", sql = q)
    data6 <- run(query)
    
    q <- paste ("SELECT count(*) as repositories FROM trackers")
    query <- new ("Query", sql = q)
    data7 <- run(query)
    
    agg_data = merge(data, data1)
    agg_data = merge(agg_data, data2)
    agg_data = merge(agg_data, data6)
    agg_data = merge(agg_data, data7)
    return(agg_data)
}

GetLastActivityITS <- function(days, closed_condition) {
    # opened issues
    q <- paste("select count(*) as opened_",days,"
                from issues
                where submitted_on >= (
                      select (max(submitted_on) - INTERVAL ",days," day)
                      from issues)", sep="");
    query <- new("Query", sql = q)
    data1 = run(query)
    
    # closed issues
    q <- paste("select count(distinct(issue_id)) as closed_",days,"
                from changes
                where  ", closed_condition,"
                and changed_on >= (
                      select (max(changed_on) - INTERVAL ",days," day)
                      from changes)", sep="");
    query <- new("Query", sql = q)
    data2 = run(query)

    # people_involved    
    q <- paste ("SELECT count(distinct(pup.upeople_id)) as changers_",days,"
                 FROM changes, people_upeople pup
                 WHERE pup.people_id = changes.changed_by and
                 changed_on >= (
                     select (max(changed_on) - INTERVAL ",days," day)
                      from changes)", sep="");
                 
    query <- new ("Query", sql = q)
    data3 <- run(query)

    agg_data = merge(data1, data2)
    agg_data = merge(agg_data, data3)

    return (agg_data)

}

GetStaticCompaniesITS  <- function(startdate, enddate, identities_db) {    
    fields = 'COUNT(DISTINCT(upc.company_id)) AS companies'
    tables = GetTablesCompaniesITS(identities_db)
    filters = GetFiltersCompaniesITS()
    q <- GetSQLGlobal('changed_on', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)               
}

GetStaticCountriesITS  <- function(startdate, enddate, identities_db) {
    fields = 'COUNT(DISTINCT(upc.country_id)) AS countries'
    tables = GetTablesCountriesITS(identities_db)
    filters = GetFiltersCountriesITS()
    q <- GetSQLGlobal('changed_on', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)               
}

# Top
## TODO: use last activity subquery
GetTopClosers <- function(days = 0, startdate, enddate, identites_db, filter = c("")) {
    
    affiliations = ""
    for (aff in filter){
        affiliations <- paste(affiliations, " com.name<>'", aff ,"' and ", sep="")
    }

    date_limit = ""
    if (days != 0 ) {
        query <- new("Query",
                sql = "SELECT @maxdate:=max(changed_on) from changes limit 1")
        data <- run(query)
        date_limit <- paste(" AND DATEDIFF(@maxdate, changed_on)<",days)
    }
    q <- paste("SELECT up.id as id, up.identifier as closers,
                       count(distinct(c.id)) as closed
                FROM ",GetTablesCompaniesITS(identities_db), ", ",
                     identities_db,".companies com,
                     ",identities_db,".upeople up
                WHERE ",GetFiltersCompaniesITS() ," and
                      ", affiliations, "
                      upc.company_id = com.id and
                      c.changed_by = pup.people_id and
                      pup.upeople_id = up.id and
                      c.changed_on >= ", startdate, " and
                      c.changed_on < ", enddate, " and ",
                      closed_condition, " ", date_limit, "
                GROUP BY up.identifier
                ORDER BY closed desc
                LIMIT 10;", sep="")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

#
# REPOSITORIES
#

GetReposNameITS <- function() {
    # q <- paste ("select SUBSTRING_INDEX(url,'/',-1) AS name FROM trackers")
    q <- paste ("SELECT url AS name FROM trackers")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetRepoEvolClosed <- function(repo, closed_condition, period, startdate, enddate){    
    fields = 'COUNT(DISTINCT(issue_id)) AS closed, 
              COUNT(DISTINCT(pup.upeople_id)) AS closers'
    tables= GetTablesReposITS()
    filters = paste(GetFiltersReposITS(),'AND',closed_condition,
            "AND trackers.url=",repo)    
    q <- GetSQLPeriod(period,'changed_on', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetRepoEvolChanged <- function(repo, period, startdate, enddate){
    fields = 'COUNT(DISTINCT(c.issue_id)) AS changed,
              COUNT(DISTINCT(pup.upeople_id)) AS changers'
    tables= GetTablesReposITS()
    filters = paste(GetFiltersReposITS(),"AND trackers.url=",repo)
    q <- GetSQLPeriod(period,'changed_on', fields, tables, filters, 
            startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetRepoEvolOpened <- function(repo, period, startdate, enddate){
    fields = "COUNT(submitted_by) AS opened, 
              COUNT(DISTINCT(pup.upeople_id)) AS openers"
    tables = "issues, trackers, people_upeople pup"
    filters = paste("trackers.url=",repo,"                      
                     AND issues.tracker_id = trackers.id
                     AND pup.people_id = issues.submitted_by")
    q <- GetSQLPeriod(period,'submitted_on', fields, tables, filters, 
                      startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetStaticRepoITS <- function (repo, startdate, enddate) {
    fields = "COUNT(submitted_by) AS opened, 
              COUNT(DISTINCT(pup.upeople_id)) AS openers"
    tables = "issues, trackers, people_upeople pup"
    filters = paste("trackers.url=",repo,"          
                    AND issues.tracker_id = trackers.id
                    AND pup.people_id = issues.submitted_by")
    
    q <- GetSQLGlobal('submitted_on',fields, tables, 
            filters, startdate, enddate)
    query <- new ("Query", sql = q)
    data <- run(query)
    
    fields = "COUNT(DISTINCT(pup.upeople_id)) as closers, 
              COUNT(DISTINCT(issue_id)) as closed"
    tables= GetTablesReposITS()
    filters = paste(GetFiltersReposITS(),'AND',closed_condition,
            "AND trackers.url=",repo)    
    q <- GetSQLGlobal('changed_on',fields, tables, 
            filters, startdate, enddate)
                         
    query <- new ("Query", sql = q)
    data1 <- run(query)
    
    fields = "COUNT(DISTINCT(pup.upeople_id)) as changers,
              COUNT(DISTINCT(issue_id)) as changed"
    tables= GetTablesReposITS()
    filters = paste(GetFiltersReposITS(),"AND trackers.url=",repo)    
    q <- GetSQLGlobal('changed_on',fields, tables, 
            filters, startdate, enddate)    
    query <- new ("Query", sql = q)
    data2 <- run(query)
    
    agg_data = merge(data, data1)
    agg_data = merge(agg_data, data2)
    return(agg_data)
}


#
# Companies
#
# TODO: Strange companies name order using issues and not closed like countries
GetCompaniesNameITS <- function(startdate, enddate, identities_db, filter=c()) {
    # companies_limit = 30    
    affiliations = ""
    for (aff in filter){
        affiliations <- paste(affiliations, " com.name<>'",aff,"' and ",sep="")
    }
    tables = GetTablesCompaniesITS(identities_db)
    tables = paste(tables,",",identities_db,".companies com")
                    
    q <- paste ("SELECT DISTINCT(com.name)
                 FROM ", tables, "
                 WHERE ", GetFiltersCompaniesITS()," AND
                 com.id = upc.company_id and
                 ",affiliations,"
                 c.changed_on >= ", startdate, " AND
                 c.changed_on < ", enddate, "
                 group by com.name
                 order by count(distinct(c.issue_id)) desc", sep="")
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}

GetCompanyClosed <- function(company_name, closed_condition, period, 
        startdate, enddate, identities_db, evol){
    
    fields = "COUNT(DISTINCT(issue_id)) AS closed,
              COUNT(DISTINCT(pup.upeople_id)) AS closers"
    tables = GetTablesCompaniesITS(identities_db)
    tables = paste(tables,",",identities_db,".companies com")
    filters = paste(GetFiltersCompaniesITS()," AND ",closed_condition,"
                AND upc.company_id = com.id
                AND com.name = ",company_name,"")
    if (evol) {
        q <- GetSQLPeriod(period,'changed_on', fields, tables, filters, 
            startdate, enddate)
    } else {
        q <- GetSQLGlobal('changed_on', fields, tables, filters, 
                            startdate, enddate)
    }
    return (q) 
}

GetCompanyEvolClosed <- function(company_name, closed_condition, period, 
        startdate, enddate, identities_db){
    q <- GetCompanyClosed (company_name, closed_condition, period, 
                    startdate, enddate, identities_db, TRUE)
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}

GetCompanyChanged <- function(company_name, period, startdate, enddate, identities_db, evol){
    
    fields = "COUNT(DISTINCT(issue_id)) AS changed,
            COUNT(DISTINCT(pup.upeople_id)) AS changers"
    tables = GetTablesCompaniesITS(identities_db)
    tables = paste(tables,",",identities_db,".companies com")
    filters = paste(GetFiltersCompaniesITS(), 
            "AND upc.company_id = com.id AND com.name = ",company_name,"")
    if (evol) {
        q = GetSQLPeriod(period,'changed_on', fields, tables, filters, 
                startdate, enddate)
    } else {
        q = GetSQLGlobal('changed_on', fields, tables, filters, 
                startdate, enddate)
    }
    return (q)            
}

GetCompanyEvolChanged <- function(company_name, period, startdate, enddate, identities_db){    
    q <- GetCompanyChanged(company_name, period, startdate, enddate, identities_db, TRUE)
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)    
}

GetCompanyOpened <- function(company_name, period, startdate, enddate, identities_db, evol){    
    q=''
    fields = "COUNT(submitted_by) AS opened,
            COUNT(DISTINCT(pup.upeople_id)) AS openers"
    tables = paste("issues, people_upeople pup,",
            identities_db,".upeople_companies upc,",
            identities_db,".companies com")
    filters = paste("pup.people_id = issues.submitted_by
                    AND pup.upeople_id = upc.upeople_id
                    AND upc.company_id = com.id
                    AND submitted_on >= upc.init
                    AND submitted_on < upc.end
                    AND com.name = ",company_name)
    if (evol) {
        q = GetSQLPeriod(period,'submitted_on', fields, tables, filters, 
                startdate, enddate)
    } else {
        fields = paste(fields,
                       ",DATE_FORMAT (min(submitted_on),'%Y-%m-%d') as first_date,
                        DATE_FORMAT (max(submitted_on),'%Y-%m-%d') as last_date")
        q = GetSQLGlobal('submitted_on', fields, tables, filters, 
                startdate, enddate)
    }
    return (q)
}
    

GetCompanyEvolOpened <- function(company_name, period, startdate, enddate, identities_db){    
    q <- GetCompanyOpened (company_name, period, startdate, enddate, identities_db, TRUE)
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}


GetCompanyStaticITS <- function (company_name, closed_condition, startdate, 
        enddate, identities_db) {
    
    period = ''
    q <- GetCompanyOpened (company_name, period, startdate, enddate, identities_db, FALSE)
    query <- new ("Query", sql = q)
    data0 <- run(query)

    q <- GetCompanyClosed (company_name, closed_condition, period, startdate, 
            enddate, identities_db, FALSE)
    
    query <- new ("Query", sql = q)
    data1 <- run(query)

    q <- GetCompanyChanged (company_name, period, startdate, 
            enddate, identities_db, FALSE)
    
    query <- new ("Query", sql = q)
    data2 <- run(query)

    q <- paste ("SELECT count(distinct(tracker_id)) as trackers
                 FROM issues,
                      changes,
                      people_upeople pup,
                      ",identities_db,".upeople_companies upc,
                      ",identities_db,".companies com
                 WHERE issues.id = changes.issue_id
                       AND pup.people_id = changes.changed_by
                       AND pup.upeople_id = upc.upeople_id
                       AND upc.company_id = com.id
                       AND com.name = ",company_name,"
                       AND changed_on >= ",startdate," AND changed_on < ",enddate,"
                       AND changed_on >= upc.init
                       AND changed_on < upc.end")
    query <- new ("Query", sql = q)
    data3 <- run(query)
  
    
    agg_data = merge(data0, data1)
    agg_data = merge(agg_data, data2)
    agg_data = merge(agg_data, data3)
    return(agg_data)
}

GetCompanyTopClosers <- function(company_name, startdate, enddate, 
        identities_db, filter = c('')) {
    affiliations = ""
    for (aff in filter){
        affiliations <- paste(affiliations, " AND up.identifier<>'",aff,"' ",sep='')
    }
    q <- paste("SELECT up.id as id, up.identifier as closers,
                       COUNT(DISTINCT(c.id)) as closed
                FROM ", GetTablesCompaniesITS(identities_db),",
                     ",identities_db,".companies com,
                     ",identities_db,".upeople up
                WHERE ", GetFiltersCompaniesITS()," AND ", closed_condition, "
                      AND pup.people_id = up.id
                      AND upc.company_id = com.id
                      AND com.name = ",company_name,"
                      AND changed_on >= ",startdate," AND changed_on < ",enddate,
                      affiliations, "
                GROUP BY changed_by ORDER BY closed DESC LIMIT 10;",sep='')
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

GetTopClosersByAssignee <- function(days = 0, startdate, enddate, identities_db, filter = c("")) {

    affiliations = ""
    for (aff in filter){
        affiliations <- paste(affiliations, " com.name<>'", aff ,"' and ", sep="")
    }

    date_limit = ""
    if (days != 0 ) {
        query <- new("Query",
                sql = "SELECT @maxdate:=max(changed_on) from changes limit 1")
        data <- run(query)
        date_limit <- paste(" AND DATEDIFF(@maxdate, changed_on)<",days)
    }
    q <- paste("SELECT up.id as id, 
                       up.identifier as closers, 
                       count(distinct(ill.issue_id)) as closed 
                FROM people_upeople pup, 
                     ", identities_db, ".upeople_companies upc, 
                     ", identities_db, ".upeople up, 
                     ", identities_db, ".companies com,
                     issues_log_launchpad ill 
                WHERE ill.assigned_to = pup.people_id and 
                      pup.upeople_id = up.id and 
                      up.id = upc.upeople_id and 
                      upc.company_id = com.id and
                      ", affiliations, "
                      ill.date >= upc.init and 
                      ill.date < upc.end and 
                      ill.change_id  in ( 
                                     select id 
                                     from changes 
                                     where new_value='Fix Committed' and 
                                           changed_on>=", startdate, " and 
                                           changed_on<", enddate, " ", date_limit,") 
                GROUP BY up.identifier 
                ORDER BY closed desc limit 10;", sep="")

    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}



# COUNTRIES

GetCountriesNamesITS <- function (identities_db,startdate, enddate, filter=c()) {
    countries_limit = 30
    
    affiliations = ""
    for (aff in filter){
        affiliations <- paste(affiliations, " cou.name<>'",aff,"' and ",sep="")
    }

    tables = GetTablesCountriesITS(identities_db)
    tables = paste(tables,",",identities_db,".countries cou")
    
    
    q <- paste("SELECT count(c.id) as closed, cou.name as name
                FROM ", tables,"
                WHERE ", GetFiltersCountriesITS()," AND
                   ", closed_condition, "
                   AND upc.country_id = cou.id
                   AND changed_on >= ",startdate," AND changed_on < ",enddate,"
                GROUP BY cou.name order by closed desc limit ", countries_limit, sep="")
	query <- new("Query", sql = q)
	data <- run(query)	
	return (data)             
}

GetCountriesITS <- function(identities_db, country, period, startdate, enddate, evol) {
    
    fields = "COUNT(c.id) AS closed,
              COUNT(DISTINCT(c.changed_by)) as closers"
    tables = GetTablesCountriesITS(identities_db)
    tables = paste(tables,",",identities_db,".countries cou")
          
    filters = paste(GetFiltersCountriesITS()," AND ", closed_condition, "
            AND upc.country_id = cou.id
            AND changed_on >= ",startdate," AND changed_on < ",enddate," AND
            cou.name = '", country,"' ", sep='')

    if (evol) {
        q = GetSQLPeriod(period,'changed_on', fields, tables, filters, 
            startdate, enddate)
    } else {
        fields = paste(fields,
                ",DATE_FORMAT (min(changed_on),'%Y-%m-%d') as first_date,
                  DATE_FORMAT (max(changed_on),'%Y-%m-%d') as last_date")
        q = GetSQLGlobal('changed_on', fields, tables, filters, 
            startdate, enddate)
    }
    return (q)
}

GetCountriesEvolITS <- function(identities_db, country, period, startdate, enddate) {
    q <- GetCountriesITS(identities_db, country, period, startdate, enddate, TRUE)    
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}

GetCountriesStaticITS <- function(identities_db, country, startdate, enddate) {
    q <- GetCountriesITS(identities_db, country, period, startdate, enddate, FALSE)      
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}

#
# People
# 

# TODO: It is the same than SCM because unique identites
GetPeopleListITS <- function(startdate, enddate) {
    fields = "DISTINCT(pup.upeople_id) as id"
    tables = GetTablesOwnUniqueIdsITS()
    filters = GetFiltersOwnUniqueIdsITS()
    q = GetSQLGlobal('changed_on',fields,tables, filters, startdate, enddate)        
	query <- new("Query", sql = q)
	data <- run(query)
	return (data)        
}

GetPeopleQueryITS <- function(developer_id, period, startdate, enddate, evol) {    
    fields = "COUNT(c.id) AS closed"
    tables = GetTablesOwnUniqueIdsITS()
    filters = paste(GetFiltersOwnUniqueIdsITS(), "AND pup.upeople_id = ", developer_id)
    
    if (evol) {
        q = GetSQLPeriod(period,'changed_on', fields, tables, filters, 
                            startdate, enddate)
    } else {
        fields = paste(fields,
                ",DATE_FORMAT (min(changed_on),'%Y-%m-%d') as first_date,
                  DATE_FORMAT (max(changed_on),'%Y-%m-%d') as last_date")
        q = GetSQLGlobal('changed_on', fields, tables, filters, 
                            startdate, enddate)
    }
    return (q)
}


GetPeopleEvolITS <- function(developer_id, period, startdate, enddate) {
    q <- GetPeopleQueryITS(developer_id, period, startdate, enddate, TRUE)    
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}

GetPeopleStaticITS <- function(developer_id, startdate, enddate) {
    q <- GetPeopleQueryITS(developer_id, period, startdate, enddate, FALSE)      
    query <- new("Query", sql = q)
    data <- run(query)	
    return (data)
}
    


#
# EXPERIMENTAL ZONE
#

#
# Identities tool
#

its_people <- function() {
    q <- paste ("select id,name,email,user_id from people")
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}


#
# SCR: Gerrit support
#

# evol_opened but with an extra condition to filter strange cases in OpenStack gerrit
evol_opened_gerrit <- function (period, startdate, enddate) {
    q <- paste("SELECT ((to_days(submitted_on) - to_days(",startdate,")) div ",period,") as id,
                    COUNT(submitted_by) AS opened,
                    COUNT(DISTINCT(pup.upeople_id)) AS openers
                                    FROM issues, issues_ext_gerrit,
                    people_upeople pup
                                    WHERE pup.people_id = issues.submitted_by AND
                    issues.id = issues_ext_gerrit.issue_id AND submitted_on<mod_date
                    AND submitted_on >= ",startdate," AND submitted_on < ",enddate,"
                                    GROUP BY ((to_days(submitted_on) - to_days(",startdate,")) div ",period,")")
    print(q)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

evol_closed_gerrit <- function (period, startdate, enddate) {
    q <- paste("SELECT ((to_days(mod_date) - to_days(",startdate,")) div ",period,") as id,
                    COUNT(submitted_by) AS closed,
                    COUNT(DISTINCT(pup.upeople_id)) AS closers
                                    FROM issues, issues_ext_gerrit,
                    people_upeople pup
                                    WHERE pup.people_id = issues.submitted_by AND
                    issues.id = issues_ext_gerrit.issue_id AND submitted_on<mod_date
                    AND mod_date >= ",startdate," AND mod_date < ",enddate,"
                    AND (status='MERGED' or status='ABANDONED')
                                    GROUP BY ((to_days(submitted_on) - to_days(",startdate,")) div ",period,")")
    print(q)
    query <- new ("Query", sql = q)
    data <- run(query)
    return (data)
}

