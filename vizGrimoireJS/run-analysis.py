#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright (C) 2013 Bitergia
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# Authors :
#       Luis Cañas-Díaz <lcanas@bitergia.com>
#       Daniel Izquierdo Cortázar <dizquierdo@bitergia.com>
#       Alvaro del Castillo San Felix <acs@bitergia.com>
#
# launch.py
#
# This script executes R scripts in order to generate the
# JSON files

import os
import sys
import time

from optparse import OptionParser
from ConfigParser import SafeConfigParser

# conf variables from file(see read_main_conf)
options = {}

def get_options():
    parser = OptionParser(usage='Usage: %prog [options]',
                          description='Executes the R scripts which analyze the information stored in the relational data bases and produce JSON files',
                          version='0.1')

    parser.add_option('-f', dest='config_file', 
                      help='File path with the configuration for the R scripts',
                      default=None)

    (ops, args) = parser.parse_args()

    if ops.config_file is None:
        parser.print_help()
        print("Configuration file is required")
        sys.exit(1)
    return ops

def read_main_conf(config_file):
    parser = SafeConfigParser()
    fd = open(config_file, 'r')
    parser.readfp(fd)
    fd.close()

    sec = parser.sections()
    # we'll read "generic" for db information and "r" for start_date
    for s in sec:
        if not((s == "generic") or (s == "r") or (s == "bicho")):
            continue
        options[s] = {}
        opti = parser.options(s)
        for o in opti:
            options[s][o] = parser.get(s, o)
    return options


#
# Functions used to write to the main log.
#
# def compose_msg(text):
#     # append text to log file
#     fd = open(msg_body, 'a')
#     time_tag = '[' + time.strftime('%H:%M:%S') + ']'
#     fd.write(time_tag + ' ' + text)
#     fd.write('\n')
#     fd.close()


# def reset_log():
#     # remove log file
#     try:
#         os.remove(msg_body)
#     except OSError:
#         fd = open(msg_body, 'w')
#         fd.write('')
#         fd.close()


def check_configuration():
    if 'db_bicho' in options['generic']:
        try:
            'backend' in options['bicho'] == True
        except:
            print "Configuration error: Configuration section for [bicho] with 'backend'\
 variable expected"
            sys.exit(-1)

def get_vars():
    v = {}
    v = options['generic']
    v.update(options['r'])
    if 'db_bicho' in v:
        v.update(options['bicho'])

    # if end_date is not present or is empty we set up today's date
    if not ('end_date' in v):
        v['end_date'] = time.strftime('%Y-%m-%d')    
        
    #log_file
    v['log_file'] = '/tmp/prueba.log'
    return v

def execute_scm_script(myvars):
    v = myvars
OA    print("Starting SCM analysis ..")
    os.system("LANG= R_LIBS=%s R --vanilla --args -r %s -d %s -u %s -p %s -i %s -s %s -e %s -o %s -g %s < scm-analysis.R >> %s 2>&1" %
              (v['r_libs'], v['reports'], v['db_cvsanaly'], v['db_user'],
               v['db_password'], v['db_identities'], v['start_date'],
               v['end_date'], v['json_dir'], v['period'], v['log_file']))
    

    print("SCM analysis finished")

def execute_its_script(myvars):
    v = myvars
    print("Starting ITS analysis  ..")
    os.system("LANG= R_LIBS=%s R --vanilla --args -r %s -d %s -u %s -p %s -i %s -s %s -e %s -o %s -g %s -t %s < its-analysis.R >> %s 2>&1" %
              (v['r_libs'], v['reports'], v['db_bicho'], v['db_user'],
               v['db_password'], v['db_identities'], v['start_date'],
               v['end_date'], v['json_dir'], v['period'], v['backend'],
               v['log_file']))    
    print("ITS analysis finished")

def execute_mls_script(myvars):
    v = myvars
    print("Starting MLS analysis  ..")
    os.system("LANG= R_LIBS=%s R --vanilla --args -r %s -d %s -u %s -p %s -i %s -s %s -e %s -o %s -g %s < mls-analysis.R >> %s 2>&1" %
              (v['r_libs'], v['reports'], v['db_mlstats'], v['db_user'],
               v['db_password'], v['db_identities'], v['start_date'], v['end_date'],
               v['json_dir'], v['period'], v['log_file']))    
    print("MLS analysis finished")

    
def execute_scr_script(myvars):
    if not 'db_gerrit' in myvars:
        print("SRC analysis disabled")
        return
    v = myvars
    print("Starting SCR analysis  ..")
    os.system("LANG= R_LIBS=%s R --vanilla --args -r %s -d %s -u %s -p %s -i %s -s %s -e %s -o %s -g %s < src-analysis.R >> %s 2>&1" %
              (v['r_libs'], v['reports'],v['db_gerrit'],v['db_user'],v['db_password'],
               v['db_identities'],v['start_date'],v['end_date'],v['json_dir'],
               v['period'],v['log_file']))    
    print("SCR analysis finished")
    

def execute_irc_script(myvars):
    if not 'db_gerrit' in myvars:
        print("IRC analysis disabled")
        return
    v = myvars
    print("Starting IRC analysis  ..")
    os.system("LANG= R_LIBS=%s R --vanilla --args -r %s -d %s -u %s -p %s -i %s -s %s -e %s -o %s -g %s < irc-analysis.R >> %s 2>&1" %
              (v['r_libs'], v['reports'],v['db_irc'],v['db_user'],v['db_password'],
               v['db_identities'],v['start_date'],v['end_date'],v['json_dir'],
               v['period'],v['log_file']))    
    print("SCR analysis finished")

    

if __name__ == '__main__':
    opt = get_options()
    read_main_conf(opt.config_file)
    check_configuration()
    myvars = {}
    myvars = get_vars()

    execute_scm_script(myvars)
    execute_its_script(myvars)
    execute_mls_script(myvars)
    execute_scr_script(myvars)
    execute_irc_script(myvars)
    

