#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 
# 
require "numru/ggraph"
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/utiles.rb")
require File.expand_path(File.dirname(__FILE__)+"/gphys-ext_dcpam.rb")
include NumRu
include Math
include NMath
include AnalyDCPAM

module AnalyDCPAM
  module Diagnose
    def sig2press(gp,ps,sig=nil) # 鉛直座標変換(sig -> press)
      # 座標データ取得
      sig = gp.axis(-2).to_gphys
      
      # 気圧データの準備
      press = calc_press
      
      # 補助座標に気圧を設定 
      gp.set_assoc_coords([press])
      
      # 気圧座標の値を準備
      press_crd = VArray.new( sig.val*RefPrs, {"units"=>"Pa"}, "press")
      
      # 鉛直座標を気圧に変換
      gp_press = gp.interpolate(sig.name=>press_crd)
      
      return gp_press
    end    
    #----------------------------------------- 
    def sig2press_save(dir,data_name) # 鉛直座標変換(sig -> press)
      # ファイルオープン
      gphys = gpopen dir + data_name +".nc"
      gps = gpopen dir + "Ps.nc"
      return if gphys.nil? || gps.nil?

      # 座標データ取得
      sig = gphys.axis(-2).to_gphys
      
      ofile = NetCDF.create(dir + 'Prs_' + data_name + '.nc')
      GPhys::NetCDF_IO.each_along_dims_write([gphys,gps],ofile, 'time')  
        |gp,ps|  
        
        gp_press = sig2press(gp,ps,sig)
        # 出力
        [gp_press]
      }
      print "[Prs_#{data_name}](#{dir}) is created\n"     
    end
    # ----------------------------------------------
    def calc_msf(vwind,ps,sigm=nil)
      time = vwind.axis("time")
      sigm = gpopen( vwind.data.path, "sigm") if sigm.nil?    
      msf_va = VArray.new(
                          NArray.sfloat(
                                        lon.length,lat.length,sigm.length,time.length))
      
      grid = Grid.new(lon,lat,sigm.axis("sigm"),time)
      msf = GPhys.new(grid,msf_va)
      msf.units = 'kg.s-1'
      msf.long_name = 'mass stream function'
      msf.name = data_name
      msf[false] = 0
      
      cos_phi = ( vwind.axis("lat").to_gphys * (PI/180.0) ).cos
      alph = vwind * cos_phi * ps * RPlanet * PI * 2 / Grav 
      (0..sigm.length-2).reverse.each do |k|
        msf[false,k,true] = msf[false,k+1,true] +
          alph[false,k,true] * (sigm[k].val - sigm[k+1].val) 
      end
      return msf
    end
    # ----------------------------------------------
    def calc_msf_save(dir)  # 質量流線関数の計算
      gv = gpopen dir + "V.nc"
      gps = gpopen dir + "Ps.nc"
      sigm = gpopen dir + "V.nc","sigm"

      return if gv.nil? || gps.nil?

      # 座標データの取得
      lon = gv.axis("lon")
      lat = gv.axis("lat")
      
      data_name = 'MSF'
      ofile = NetCDF.create(dir + data_name + '.nc')
      GPhys::NetCDF_IO.each_along_dims_write([gv,gps], ofile, 'time') { 
      |vwind,ps|  
        msf = calc_msf(vwind,ps,sigm)
        [msf]
      }
      ofile.close
      print "[#{data_name}](#{dir}) is created\n"
    end
    # -------------------------------------------
    def calc_rh_save(dir) # 相対湿度の計算
      gtemp = gpopen dir + "Temp.nc"
      gqvap = gpopen dir + "QVap.nc"
      gps = gpopen dir + "Ps.nc"
 
      return if gtemp.nil? || gqvap.nil? || gps.nil?

      sig = gtemp.axis('sig').to_gphys
      
      # 定数設定
      es0 = UNumeric[611,"Pa"]      
      epsv = MolWtWet / MolWtDry
      
      # 
      data_name = 'RH'
      ofile = NetCDF.create(dir + data_name + '.nc')
      GPhys::NetCDF_IO.each_along_dims_write([gqvap,gps,gtemp],ofile,'time'){ 
        |qvap,ps,temp| 

        press = calc_press(ps,sig)    
        
        # Teten 
        es = es0 * ( LatentHeat / GasRWet * ( 1/273.0 - 1/temp ) ).exp
        e = qvap * press / epsv
        rh = e / es * 100 # [%]
        
        rh.units = '%'
        rh.long_name = 'relative humidity'
        rh.name = data_name  
        
        [rh]
      }
      ofile.close
      print "[#{data_name}](#{file}) is created\n"
    end
    # --------------------------------------------
    def calc_prcwtr_save(gqv,gps,sigm) # 可降水量の計算           
      gqvap = gpopen dir + "QVap.nc"
      gps = gpopen dir + "Ps.nc"
      sigm = gpopen dir + "QVap.nc","sigm"

      return if gqvap.nil? || gps.nil?

      data_name = 'PrcWtr' 
      ofile = NetCDF.create(dir + data_name + '.nc')
      GPhys::NetCDF_IO.each_along_dims_write([gqv,gps], ofile, 'time') { 
        |qvap,ps|  
        
        time = qvap.axis("time")    
        
        qc = ps.copy
        qc.units = 'kg.m-2'
        qc.long_name = 'precipitable water'
        qc.name = data_name
        qc[false] = 0
        
        alph = qvap * ps / Grav 
        kmax = qvap.axis("sig").length-1
        for i in 0..kmax
          k = kmax-i
          qc = qc + alph[false,k,true] * (sigm[k].val - sigm[k+1].val) 
        end
        [qc]
      }
      ofile.close
      print "[#{data_name}](#{dir}) is created\n"
    end
    # ---------------------------------------
    def calc_correlat_coef(x,y)  # 相関係数の計算 
      x_mean = x.glmean
      y_mean = y.glmean
      xy_S = ((x-x_mean)*(y-y_mean))
      xx_S = ((x-x_mean)**2)
      yy_S = ((y-y_mean)**2)
      coef = xy_S/(xx_S * yy_S).sqrt
      return coef
    end  
    # ---------------------------------------
    def calc_regression_coef(x,y)
      x_mean = x.glmean
      y_mean = y.glmean
      xy_S = ((x-x_mean)*(y-y_mean)).glmean
      xx_S = (x-x_mean)**2).glmean
      return xy_S/xx_S      
    end
    # ---------------------------------------
    def potential_temperature(temp,press)  
      return temp*(RefPrs/press)**(GasRDry/CpDry) 
    end
    # ---------------------------------------
    def equiv_potential_temperature(temp,qvap,press)
      return potential_temperature(temp,press)*(qvap*LatentHeat/(CpDry*temp)).exp 
    end
  end
end
