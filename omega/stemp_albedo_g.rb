#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 自転角速度変更実験用スクリプト
#

require "numru/ggraph"
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/utiles_omega.rb")
require 'optparse'
include Omega
include NumRu
include Math
include NMath

  def get_albedo(list)
    albedo = []
    error = []
    list.dir.each_index{ |n| 
      osr = GPhys::IO.open(list.dir[n] + "OSRA.nc","OSRA")
      if list.id.include?("diurnal") then    
        osr = time_range2(osr,list.name[n])
      else
        osr = time_range(osr,list.name[n])
      end
      alb = 1.0 + Utiles_spe.glmean(osr)/(SolarConst/4) 
      albedo << alb.mean("time").val
      error << std_error(alb.val)
    }
    return albedo, error
  end
  
  def get_surftemp(list)
    stemp = []
    error = []
    list.dir.each_index{ |n| 
      temp = GPhys::IO.open(list.dir[n] + "SurfTemp.nc","SurfTemp")
      if list.id.include?("diurnal") then    
        temp = time_range2(temp,list.name[n])
      else
        temp = time_range(temp,list.name[n])
      end
      st = Utiles_spe.glmean(temp)
      stemp << st.mean("time").val
      error << std_error(st.val)    
    }
    return stemp, error
  end
  
  def get_greenhouse(list)
    green = []
    error = []
    list.dir.each_index{ |n| 
      temp = GPhys::IO.open(list.dir[n] + "SurfTemp.nc","SurfTemp")
      osr = GPhys::IO.open(list.dir[n] + "OSRA.nc","OSRA")
      if list.id.include?("diurnal") then    
        osr = time_range2(osr,list.name[n])
        temp = time_range2(temp,list.name[n])
      else
        osr = time_range(osr,list.name[n])
        temp = time_range(temp,list.name[n])
      end
      factor= (Utiles_spe.glmean(temp)/
                (SolarConst*
                  (1.0-(1.0 + Utiles_spe.glmean(osr)/(SolarConst/4)))/
                  (4*5.67e-8)
                )**(1.0/4))
      green << factor.mean("time").val
      error << std_error(factor.val)
    }
    return green, error
  end
  
  def get_omega(list)
    omega = []
    list.name.each{ |nm|
      omega << Utiles_spe.omega_ratio(nm)
    }
    return omega
  end
  
  def time_range(gp,name)
    if gp.axis("time").length == 1441 or 1440
      result = gp[false,-360..-1]
    elsif gp.axis("time").pos.units.to_s == "day"
      gp = Utiles_spe.day2hrs(gp,name)
      result = gp.cut("time"=>1080*24..1440*24)
    elsif gp.axis("time").pos.units.to_s == "hrs"
      result = gp.cut("time"=>1080*24..1440*24)
    end
    return result
  end
  
  def time_range2(gp,name)
    if gp.axis("time").length == 1441 
      result = gp[false,-360..-1]
    elsif gp.axis("time").pos.units.to_s == "day"
      gp = Utiles_spe.day2hrs(gp,name)
      result = gp.cut("time"=>1080*24..1440*24)
    elsif gp.axis("time").pos.units.to_s == "hrs"
      result = gp.cut("time"=>1080*24..1440*24)
    end
    return result
  end
  
  def error_sd(gp)
    tmax = gp.axis("time").length
    g = []
    g[0] = gp[0..tmax/4-1].mean("time")
    g[1] = gp[tmax/4..tmax/2-1].mean("time")
    g[2] = gp[tmax/2..tmax*3/4-1].mean("time")
    g[3] = gp[tmax*3/4..-1].mean("time")
    gpmean = gp.mean("time") 
    std = 0
    g.each_index{ |n|
      std = std + (g[n]-gpmean)**2  
    }
    std = (std/g.length).sqrt
    return std
  end
#---------------------------------------------
  def drawfig(file,chpt="a")
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
    clrmp = 5  # カラーマップ
    DCL.sgscmn(clrmp)
    DCL.gropn(iws)
    # DCL.sldiv('Y',2,1)
    DCL.sgpset('lcntl',true)
    DCL.sgpset('isub', 96)
    DCL.uzfact(0.9) # 文字の大きさ
  
    type = 5
    index = 102
    size = 0.02
    lc = 130
    vx = 0.82
    vy = 0.8
  
    case chpt
    when "a"
      subname= "(a)"
      GGraph.set_fig "itr"=>3, "window"=>[0.05,10.0,255,310]
      long_name = "surface temperature"
    when "b"
      subname= "(b)"
      GGraph.set_fig "itr"=>3, "window"=>[0.05,10.0,0,0.5]
      long_name = "planetary albedo"
    when "c"
      subname= "(c)"
      GGraph.set_fig "itr"=>3, "window"=>[0.05,10.0,1.0,1.18]
      long_name = "factor G"
    end
    name = ["Series A","Series C","Series D"]
    file.each_index{ |n|
      list = Utiles_spe::Explist.new(file[n])
  
      case chpt
      when "a"
        albedo = Utiles_spe.array2gp(get_omega(list),get_surftemp(list))  
      when "b"
        albedo = Utiles_spe.array2gp(get_omega(list),get_albedo(list))  
      when "c"
        albedo = Utiles_spe.array2gp(get_omega(list),get_greenhouse(list))
      end
      albedo.long_name = long_name
      albedo.name = "Albedo"  
      omega = albedo.axis("noname").pos
      omega.name = "omega"
      omega.long_name = "Rotation rate"
      albedo.axis("noname").set_pos(omega)
      error = std_error(albedo.val,4)
      p error
  
      if n == 0 then
        GGraph.scatter albedo.axis("noname").to_gphys,albedo, true,"size"=>size,"index"=>12,"type"=>type-1,"title"=>subname+" "+long_name 
        DCL.sgtxzv(vx+0.03,vy,name[n],size,0,-1,3)
        DCL::sgpmzv([vx],[vy],type-1,lc,size)
      else
        type += 1
        index += 200
        lc = lc + 100
        vy = vy - 0.035
  
        GGraph.scatter albedo.axis("noname").to_gphys,albedo, false,"size"=>size,"index"=>index,"type"=>type
        DCL.sgtxzv(vx+0.03,vy,name[n],size,0,-1,3)
        DCL::sgpmzv([vx],[vy],type,lc,size)
  
      end
    }
    DCL.grcls
    
    if ARGV.index("-ps") 
      system("mv dcl.ps omega_plnt-alb.ps")
    elsif ARGV.index("-png")
      system("rename 's/dcl_/omega_stemp-plntalb-g_#{chpt}_/' dcl_*.png")
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
  
  def drawclm(file)
    stemp_name = "surface temperature"
    albedo_name = "planetary albedo"
    green_name = "factor g"
  
    file.each_index do |n|
      list = Utiles_spe::Explist.new(file[n])
      fin = File.open("omega_deltemp_clm_#{list.id}.dat","w")
      stemp, stemp_error = get_surftemp(list)
      albedo, albedo_error = get_albedo(list)  
      green, green_error = get_greenhouse(list)
  
      stemp = Utiles_spe.array2gp(get_omega(list),stemp)  
      albedo = Utiles_spe.array2gp(get_omega(list),albedo)  
      green = Utiles_spe.array2gp(get_omega(list),green)
  
      omega = albedo.axis("noname").pos
      omega.name = "omega"
      omega.long_name = "Rotation rate"
      stemp.axis("noname").set_pos(omega)
      albedo.axis("noname").set_pos(omega)
      green.axis("noname").set_pos(omega)
  
      fin.print "# Omega\t"
      fin.print "Surftemp\t error\t"
      fin.print "Albedo\t error\t"
      fin.print "Green\t error\n"
      omega.val.to_a.each_index do |m|
        fin.print omega[m].val, "\t"
        fin.print stemp[m].val, "\t"
        fin.print stemp_error[m], "\t"
        fin.print albedo[m].val, "\t"
        fin.print albedo_error[m], "\t"
        fin.print green[m].val, "\t"
        fin.print green_error[m], "\n"
      end
      fin.close
    end
   
  end

opt = OptionParser.new
opt.on("-a") {type = "a"}
opt.on("-b") {type = "b"}
opt.on("-c") {type = "c"}
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

