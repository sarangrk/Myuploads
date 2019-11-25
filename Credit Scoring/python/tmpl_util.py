#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Excel template util functions

Created on Fri May 11 13:56:37 2018

@author: fd186011
"""

from collections import OrderedDict

def get_value(name, ws):
    """Gets the value of a variable specified by name.
    
    The assumption is that the name is placed on the first column, and the
    value is next right to it.
    """
    x = None
    for row in ws.values:
        # Start mapping when the list_name is found
        if row[0] and row[0] == name:
            x = row[1]

    return x


def get_variables(ws):
    """Gets the list of variables and their attributes and returns them in a
    dictionary.
    
    The assumption is that the list is contiguous, such that any blank cell in
    the variable column signifies the end.
    """
    varlist = OrderedDict()
    within_list = False
    
    for row in ws.values:
        if not within_list:
            # Start mapping when the list_name is found
            if row[0] and row[0] == "VARIABLE LIST":
                within_list = True
        else:
            # An empty name signifies the end of the list
            if row[1] == None or row[1].strip("'").strip() == "":
                break
            else:
                varlist[row[1].strip("'").strip()] =\
                    (row[2].strip("'").strip(), int(str(row[3]).strip("'").strip()))

    return varlist


def get_fine_bins(ws):
    """Gets the fine class bins of variables.
    
    The assumption is that the bin list of a variable is contiguous, such that
    any blank cell in the operator column signifies the end of the current
    variable.
    """
    bin_lists = {}
    within_list = False
    within_var = False
    varname = None
    varbins = []

    for row in ws.values:
        if not within_list:
            # Start mapping when the list_name is found
            if row[0] and row[0] == "FINE CLASS BINS":
                within_list = True
        else:
            if row[1] and row[1].strip("'").strip():
                varname = row[1].strip("'").strip()
                varbins.append((row[2].strip("'").strip(),
                                str(row[3]).strip("'").strip())) 
                within_var = True
                continue
            # An empty operator signifies the end of the current variable
            if row[2] == None or row[2].strip("'").strip() == "":
                if within_var:
                    within_var = False
                    # Add the current variable bins to the bin lists
                    bin_lists[varname] = varbins
                    varname = None
                    varbins = []
                else:
                    # Two consecutive empty rows
                    break
            else:
                varbins.append((row[2].strip("'").strip(),
                                str(row[3]).strip("'").strip())) 

    # The last variable might not have been added yet because there are no
    # empty rows after the last bin
    if varname and not bin_lists.get(varname):
        bin_lists[varname] = varbins
            
    return bin_lists


#def metabins_to_case(metabins, varname="varvalue"):
#    """"""
#    l = []
#    last_operator = None
#    last_operand = None
#    for i, (operator, operand) in enumerate(metabins):
#        if operator in ("=", ">", ">=") or i == 0:
#            l.append("WHEN {varname} {operator} {operand} THEN '{varname} {operator} {operand}'".format(varname=varname, operator=operator, operand=operand))
#        else:
#            if last_operator == "=" or last_operator == "<=":
#                operator1 = ">"
#                operator1_rev = "<"
#            elif last_operator == "<":
#                operator1 = ">="
#                operator1_rev = "<="
#            l.append("WHEN {varname} {operator1} {last_operand} AND {varname} {operator2} {operand} THEN '{last_operand} {operator1_rev} {varname} {operator2} {operand}'".format(varname=varname, operator1=operator1, last_operand=last_operand, operator1_rev=operator1_rev, operator2=operator, operand=operand))
#        last_operator = operator
#        last_operand = operand
#
#    return l
#
#
#def metabins_to_labels(metabins):
#    """"""
#    l = []
#    last_operator = None
#    last_operand = None
#    for i, (operator, operand) in enumerate(metabins):
#        if operator in ("=", ">", ">=") or i == 0:
#            l.append("{{varname}} {operator} {operand}".format(operator=operator, operand=operand))
#        else:
#            if last_operator == "=" or last_operator == "<=":
#                operator1 = ">"
#                operator1_rev = "<"
#            elif last_operator == "<":
#                operator1 = ">="
#                operator1_rev = "<="
#            l.append("{last_operand} {operator1_rev} {{varname}} {operator2} {operand}".format(operator1=operator1, last_operand=last_operand, operator1_rev=operator1_rev, operator2=operator, operand=operand))
#        last_operator = operator
#        last_operand = operand
#
#    return l


def interpret_metabins(metabins, is_categorical):
    """"""
    when_stmts = []
    labels = []
    last_operator = None
    last_operand = None

    for i, (operator, operand) in enumerate(metabins):
        # Add a bin for NULL or missing value when i == 1
        if i == 0:
            when_stmts.append("WHEN varvalue IS NULL THEN -2".format(operator=operator, operand=operand, i=i))
            labels.append("missing".format(operator=operator, operand=operand))

        if is_categorical:
            # Ignore operator if variable is categorical
            when_stmts.append("WHEN varvalue = '{operand}' THEN {i}".format(operand=operand, i=i))
            labels.append("{operand}".format(operator=operator, operand=operand))

        else:
            if operator in ("=", ">", ">=") or i == 0:
                when_stmts.append("WHEN varvalue {operator} {operand} THEN {i}".format(operator=operator, operand=operand, i=i))
                labels.append("{{varname}} {operator} {operand}".format(operator=operator, operand=operand))
            else:
                if last_operator == "=" or last_operator == "<=":
                    operator1 = ">"
                    operator1_rev = "<"
                elif last_operator == "<":
                    operator1 = ">="
                    operator1_rev = "<="
                when_stmts.append("WHEN varvalue {operator1} {last_operand} AND varvalue {operator2} {operand} THEN {i}".format(operator1=operator1, last_operand=last_operand, operator2=operator, operand=operand, i=i))
                labels.append("{last_operand} {operator1_rev} {{varname}} {operator2} {operand}".format(operator1=operator1, last_operand=last_operand, operator1_rev=operator1_rev, operator2=operator, operand=operand))
            last_operator = operator
            last_operand = operand

    # Add a catch-all bin
    when_stmts.append("ELSE -1")
    labels.insert(1, "others")

    return labels, when_stmts