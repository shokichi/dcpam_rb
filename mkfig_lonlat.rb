#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# standerd figure
# No.4 


# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu


def lonlat(var_name,dir,name,hash=nil)
  for n in 0..dir.length-1
    begin
      gp = GPhys::IO.open(dir[n] + var_name + ".nc",var_name)
    rescue
      print "[#{var_name}.nc](#{dir[n]}) is not exist\n"
      next
    end

    # 時間平均
    if gp.axnames.index("time") != nil then
      gp = gp.mean("time")
    end

    # 高さ方向の次元を無くす
    if gp.rank==3
      gp = gp[false,0]
    end

    # 
    if gp.axis(0).to_gphys.long_name == "local time" then
      max = 24
    else
      max = 360
    end

    # 描画
    GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
    GGraph.set_fig('window'=>[0,xmax,-90,90])

    fig_opt = {'title'=>gp.long_name + " " + name[n],'annotate'=>false, 'color_bar'=>true}
    GGraph.tone( gp ,true, fig_opt.merge(hash))
  end
end

=begin
def local_fig_Dt(var_name,dir,name,min,max,dtime)
  num = dir.length
  dtime =  UNumeric[dtime.to_f*60, "s"]
  for n in 0..num-1
    begin
      gp = GPhys::IO.open(dir[n] + "MT" + var_name + ".nc",var_name)
    rescue
      print "[#{var_name}.nc](#{dir[n]}) is not exist\n"
      next
    end
    if gp.rank==3 then
      gp = gp[false,0]
    end
    GGraph.tone( gp*dtime ,true, 'title'=>gp.long_name + " " + name[n],'min'=>min, 'max'=>max,'annotate'=>false, 'color_bar'=>true)
  end
end
=end


#
dir, name = Utiles_spe.explist(ARGV[0])

# DCL open
if ARGV.index("-ps")
  DCL.gropn(2)
elsif ARGV.index("-png")
  DCL::swlset('lwnd',false)
  DCL.gropn(4)
else
  DCL.gropn(1)
end

# DCL set
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

lonlat("EvapA",dir,name,"max"=>500)
lonlat("SensA",dir,name,"max"=>200)
lonlat("SSRA",dir,name,"min"=>-1000)
lonlat("SLRA",dir,name,"min"=>0,"max"=>300)
lonlat("Rain",dir,name,"min"=>0,"max"=>600)
lonlat("RainCumulus",dir,name,"min"=>0,"max"=>300)
lonlat("RainLsc",dir,name,"min"=>0,"max"=>300)
lonlat("SurfTemp",dir,name,"min"=>220,"max"=>320)
lonlat("Temp",dir,name,"min"=>220,"max"=>300)
lonlat("RH",dir,name,"min"=>0,"max"=>100,"nlev"=>20)
lonlat("OSRA",dir,name,"min"=>-1000,"max"=>0)
lonlat("OLRA",dir,name,"min"=>0,"max"=>300)
lonlat("QVap",dir,name,"min"=>0,"max"=>2e-2)

#=begin
lonlat("DQVapDtDyn",dir,name)      
lonlat("DQVapDtVDiff",dir,name)    
lonlat("DQVapDtCond",dir,name,"min"=>-3e-7,"max"=>0)
lonlat("DQVapDtCumulus",dir,name,"min"=>-3e-7,"max"=>0)  
lonlat("DQVapDtLsc",dir,name,"min"=>-3e-7,"max"=>0)
lonlat("DTempDtRadS",dir,name)
lonlat("DTempDtRadL",dir,name)
lonlat("DTempDtDyn",dir,name)   
lonlat("DTempDtVDiff",dir,name)
lonlat("DTempDtCond",dir,name)     
lonlat("DTempDtCumulus",dir,name)  
lonlat("DTempDtLsc",dir,name)   
lonlat("DTempDtDryConv",dir,name)  
#=end
DCL.grcls

if ARGV.index("-ps") 
  system("mv dcl.ps #{id_exp}_lonlat.ps")
elsif ARGV.index("-png")
  system("rename 's/dcl_/#{id_exp}_lonlat_/' dcl_*.png")
end
