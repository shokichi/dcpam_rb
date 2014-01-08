#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 
# 

require "numru/ggraph"
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/make_figure.rb")
require File.expand_path(File.dirname(__FILE__)+"/gphys-ext_dcpam.rb")
require File.expand_path(File.dirname(__FILE__)+"/gphys_array.rb")
require File.expand_path(File.dirname(__FILE__)+"/option_charge.rb")
require File.expand_path(File.dirname(__FILE__)+"/globa_ave.rb")

include NumRu
include Math
include NMath
include MKfig
include AnalyDCPAM
include OptCharge
include ConstShk
include GlobalAverage

