#!/bin/bash
gfortran -c src/cii_types.f90 -o cii_types.o
gfortran -c src/normalization.f90 -o normalization.o
gfortran -c src/inheritance.f90 -o inheritance.o
gfortran -c src/xml_parser_base.f90 -o xml_parser_base.o
gfortran -c src/xml_parser_elements.f90 -o xml_parser_elements.o
gfortran -c src/xml_parser.f90 -o xml_parser.o
gfortran -c src/main.f90 -o main.o
gfortran -o cii_converter cii_types.o normalization.o inheritance.o xml_parser_base.o xml_parser_elements.o xml_parser.o main.o
