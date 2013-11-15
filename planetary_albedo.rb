#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 自転角速度変更実験用スクリプト
#

require "numru/ggraph"
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math
include NMath

# 定数
SolarConst = UNumeric[1366.0, "W.m-2"]
StB = UNumeric[5.67e-8, "W.m-2.K-4"]

class Analy
  def initialize(list)
    @list = list
    @omega = get_omega(list)
    @albedo = get_albedo(list)
    @surftemp = get_surftemp(list)
    @green = get_greenhouse(list)
  end

  private

  def get_albedo(list)
    albedo = []
    error = []
    list.dir.each_index do |n| 
      osr = gpopen list.dir[n] + "OSRA.nc"
      
      alb = 1.0 + Utiles_spe.glmean(osr)/(SolarConst/4) 
      alb = alb.mean("time") if alb.class == "GPhys" and alb.axnames.include?("time")
      albedo << alb.val
    end
    return albedo
  end
  
  def get_surftemp(list)
    stemp = []
    error = []
    list.dir.each_index{ |n| 
      temp = gpopen list.dir[n] + "SurfTemp.nc","SurfTemp"
      temp = temp.mean("time") if temp.axnames.include?("time")
      st = Utiles_spe.glmean(temp)
      stemp << st.val
    }
    return stemp
  end
  
  def get_greenhouse(list)
    green = []
    error = []
    list.dir.each_index{ |n| 
      temp = gpopen list.dir[n] + "SurfTemp.nc"
      osr = gpopen list.dir[n] + "OSRA.nc"
      factor= (Utiles_spe.glmean(temp)/
               (SolarConst*
                (1.0-(1.0 + Utiles_spe.glmean(osr)/(SolarConst/4)))/
                (4*5.67e-8)
                )**(1.0/4))
      factor = factor.mean("time") if factor.class == "GPhys" and factor.axnames.include?("time")
      green << factor.val
    }
    return green
  end

  def get_omega(list)
    omega = []
    list.name.each{ |nm|
      omega << Utiles_spe.omega_ratio(nm)
    }
    return omega
  end

#   def error_sd(gp)
#     tmax = gp.axis("time").length
#     g = []
#     g[0] = gp[0..tmax/4-1].mean("time")
#     g[1] = gp[tmax/4..tmax/2-1].mean("time")
#     g[2] = gp[tmax/2..tmax*3/4-1].mean("time")
#     g[3] = gp[tmax*3/4..-1].mean("time")
#     gpmean = gp.mean("time") 
#     std = 0
#     g.each_index{ |n|
#       std = std + (g[n]-gpmean)**2  
#     }
#     std = (std/g.length).sqrt
#     return std
#   end

  public
  attr_reader :list, :omega, :green, :albedo, :surftemp
end


def drawclm(file)
  file.each_index do |n|
    list = Utiles_spe::Explist.new(file[n])
    data = Analy.new(list)

    omega = data.omega
    stemp = data.surftemp
    albedo = data.albedo  
    green = data.green

    fin = File.open("omega_deltemp_clm_#{list.id}.dat","w")
    fin.print "#rotation_rate\t"
    fin.print "surftemp\t"
    fin.print "albedo\t"
    fin.print "green\n"
    omega.each_index do |m|
      fin.print omega[m], "\t"
      fin.print stemp[m], "\t"
      fin.print albedo[m], "\t"
      fin.print green[m], "\n"
    end
    fin.close
  end 
end 

def drawclm_deltemp(file)
  stemp_name = "surface temperature"
  albedo_name = "planetary albedo"
  green_name = "factor g"

  fin = File.open("omega_deltemp_clm.dat","w")
  fin.print  "Rotation rate","\t"
  fin.print  stemp_name,"\t"
  fin.print  albedo_name,"\t"
  fin.print  green_name,"\n"

  file.each_index do |n|
    list = Utiles_spe::Explist.new(file[n])

    stemp = Utiles_spe.array2gp(get_omega(list),get_surftemp(list))  
    albedo = Utiles_spe.array2gp(get_omega(list),get_albedo(list))  
    green = Utiles_spe.array2gp(get_omega(list),get_greenhouse(list))

    omega = albedo.axis("noname").pos
    omega.name = "omega"
    omega.long_name = "Rotation rate"
    stemp.axis("noname").set_pos(omega)
    albedo.axis("noname").set_pos(omega)
    green.axis("noname").set_pos(omega)

    radtemp = (SolarConst*(1-albedo.cut("noname"=>1).val)/(4*StB))**0.25

    delstemp = stemp.val - stemp.cut("noname"=>1).val
    delalbedo = albedo.val - albedo.cut("noname"=>1).val
    delgreen = green.val - green.cut("noname"=>1).val

    albedo_error = std_error(albedo.val,4)
    stemp_error = std_error(stemp.val,4)
    green_error = std_error(green.val,4)

    fin.print "--- #{file[n].split("/")[-1].sub(".list","").sub("omega_","")} ---\n"
    omega.val.to_a.each_index do |m|
      fin.print omega[m].val, "\t"
      fin.print delstemp[m], "\t"
      fin.print -radtemp.val * delalbedo[m]/(4*(1-albedo.cut("noname"=>1).val)), "\t"
      fin.print radtemp.val * delgreen[m], "\n"
    end
  end
  fin.close
 
end 


opt = OptionParser.new
opt.parse!(ARGV)


file_all = "/home/ishioka/link/all/fig/list/omega_all_MTlocal.list"
file_coriolis = "/home/ishioka/link/coriolis/fig/list/omega_coriolis_MTlocal.list"
file_diurnal = "/home/ishioka/link/diurnal/fig/list/omega_diurnal_MTlocal.list"


#drawfig([file_all,file_coriolis,file_diurnal],type)
drawclm([file_all,file_coriolis,file_diurnal])
#list = Utiles_spe::Explist.new(file_all)
#albedo = Utiles_spe.array2gp(get_omega(list),get_albedo(list))
#GGraph.scatter albedo.axis("noname").to_gphys,albedo, false
#list = Utiles_spe::Explist.new(file_all)
#albedo = Utiles_spe.array2gp(get_omega(list),get_albedo(list))
#GGraph.scatter albedo.axis("noname").to_gphys,albedo, false





=begin  
def time_range(gp,name)
#  if gp.axis("time").length == 1441 or 1440
#    result = gp[false,-360..-1]
#  elsif gp.axis("time").pos.units.to_s == "day"
#    gp = Utiles_spe.day2hrs(gp,name)
#    result = gp.cut("time"=>1080*24..1440*24)
#  elsif gp.axis("time").pos.units.to_s == "hrs"
#    result = gp.cut("time"=>1080*24..1440*24)
#  end
  return result
end

def time_range2(gp,name)
#  if gp.axis("time").length == 1441 
#    result = gp[false,-360..-1]
#  elsif gp.axis("time").pos.units.to_s == "day"
#    gp = Utiles_spe.day2hrs(gp,name)
#    result = gp.cut("time"=>1080*24..1440*24)
#  elsif gp.axis("time").pos.units.to_s == "hrs"
#    result = gp.cut("time"=>1080*24..1440*24)
#  end
  return result
end
=end
