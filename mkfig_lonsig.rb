#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# standerd figure
# No.4 


# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu



#
list = Utiles_spe::Explist.new(ARGV[0])

# DCL open
if ARGV.index("-ps")
  iws = 2
elsif ARGV.index("-png")
  DCL::swlset('lwnd',false)
  iws = 4
else
  iws = 1
end

# DCL set
clrmp = 14  # カラーマップ
DCL.sgscmn(clrmp)
DCL.gropn(iws)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

lonsig("Temp",list,"min"=>120,"max"=>320,"nlev"=>20)
lonsig("DQVapDtCond",list,"min"=>-2e-7,"max"=>2e-7,"nlev"=>20)
lonsig("DQVapDtCumulus",list,"min"=>-2e-7,"max"=>2e-7,"nlev"=>20)  
lonsig("DQVapDtLsc",list,"min"=>-2e-7,"max"=>2e-7,"nlev"=>40)
lonsig("RH",list,"min"=>0,"max"=>100)
lonsig("H2OLiq",list,"min"=>0,"max"=>1e-4)
lonsig("U",list,"min"=>-20,"max"=>20,"nlev"=>20)      
lonsig("V",list,"min"=>-10,"max"=>10)      

=begin
lonlat("DQVapDtDyn",list)
lonlat("DQVapDtVDiff",list)
lonlat("DTempDtRadS",list)
lonlat("DTempDtRadL",list)
lonlat("DTempDtDyn",list)   
lonlat("DTempDtVDiff",list)
lonlat("DTempDtCond",list)     
lonlat("DTempDtCumulus",list)  
lonlat("DTempDtLsc",list)   
lonlat("DTempDtDryConv",list)  
=end
DCL.grcls


img_lg = list.id+"_lonsig"
if ARGV.index("-ps") 
  File.rename("dcl.ps","#{img_lg}.ps")
elsif ARGV.index("-png")
  Dir.glob("dcl_*.png").each{ |filename|
    File.rename(filename,filename.sub("dcl",img_lg)) }
end
