#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# make standerd figure 
# 子午面断面
#

require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu

def merid_fig(var_name,list,hash)
  list.dir.each_index do |n|
    begin
      gp = gpopen(Utiles_spe.str_add(list.dir[n],var_name)+'.nc',var_name)
    rescue
      print "[#{var_name}](#{list.dir[n]}) is not exist\n"
      next
    end
    # 時間平均
    gp = gp.mean("time") if !gp.axnames.index("time").nil
    # 経度平均
    gp = gp.mean("lon") if !gp.axnames.index("lon").nil
    
    # 
    if gp.max.to_f > 1e+10 then
      gp = gp*1e-10
      gp.units = "10^10 " + gp.units
    end

    fig_opt = {'color_bar'=>true,'title'=>gp.long_name + " " + list.name[n],'annotate'=>false,'nlev'=>20}
    GGraph.tone_and_contour(gp, true,fig_opt.merge(hash))
  end
end

def merid_fig_strm(list)
  var_name = "Strm"
  for n in 0..list.dir.length-1
    begin
#      gp = GPhys::IO.open(dir[n].sub("local_","") + var_name + '.nc',var_name)
      gp = gpopen(list.dir[n] + var_name + '.nc',var_name)
    rescue
      print "[#{varl_name}](#{list.dir[n]}) is not exist\n"
      next
    end
    gp = gp.mean(0,-1) if gp.rank != 2

    GGraph.next_linear_tone_options("min"=>-50,'max'=>50,'interval'=>5)
    GGraph.tone(gp*1e-10,true,'title'=>gp.long_name + " " + list.name[n],'annotate'=>false,"nlev"=>2)
    GGraph.contour(gp,false,'interval'=>5*1e+10)
  end
end

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
# DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(0.9) # 文字の大きさ
  
GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
GGraph.set_fig('window'=>[-90,90,nil,nil])


merid_fig('Temp',list,"min"=>120,"max"=>320,"interval"=>10)
merid_fig('U',list,"min"=>-80,"max"=>80,"interval"=>5)
merid_fig('V',list,"min"=>-8,"max"=>8)
merid_fig('RH',list,"min"=>0,"max"=>100)
merid_fig('SigDot',list,"min"=>-1.5e-6,"max"=>1.5e-6)
merid_fig('QVap',list,"min"=>0,"max"=>0.015)
merid_fig('H2OLiq',list,"min"=>0,"max"=>5e-5)
#merid_fig_strm(list)


DCL.grcls

if ARGV.index("-ps") 
  system("mv dcl.ps #{list.id}_merid.ps")
elsif ARGV.index("-png")
  system("rename 's/dcl_/#{list.id}_merid_/' dcl_*.png")
end
