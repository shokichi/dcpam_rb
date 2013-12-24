#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Global average

require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/lib/global_ave.rb")
require 'optparse'
include GlobalAverage
include NumRu


# 実行
list = Utiles_spe::Explist.new(ARGV[0])
varlist = ['OSRA','OLRA',
           'SSRA','SLRA','EvapA','SensA',
           'SurfTemp','Temp',
           'Rain','RainCumulus','RainLsc',
           'PrcWtr',
           'RadSUWFLXA','RadSDWFLXA',
           'RadLUWFLXA','RadLDWFLXA']

GlobalAverage::create_gave(list,varlist)
