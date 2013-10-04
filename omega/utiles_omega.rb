#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 自転角速度変更実験用スクリプト
#

require "numru/ggraph"
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/../lib/make_figure.rb")
require 'optparse'
include Utiles_spe
include MKfig
include NumRu
include Math
include NMath

module Omega
  # 定数
  SolarConst = UNumeric[1366.0, "W.m-2"]
  StB = UNumeric[5.67e-8, "W.m-2.K-4"]

  class Anomaly
    def initialize(data_name,list)
      @list = list
      @data_name = data_name
      get_refdata
      get_anomaly
    end
    
    def get_refdata
      dir = @list.dir[@list.refnum]
      refdata = gpopen dir+@data_name+".nc"
      if refdata.nil?
        print "Refarence file is not exist [#{@list.dir[list.refnum]}](#{@data_name})\n"
      end
      refdata = surfh2o(refdata,dir) if refdata.name == "H2OLiq"
      @@ref_data = refdata
    end
    
    def get_anomaly
      result = []
      @list.dir.each do |dir|
        gp = gpopen dir + @data_name+".nc" 
        if gp.nil? then
          result << nil
        else
          gp = surfh2o(gp,dir) if gp.name == "H2OLiq"
          result << gp - @@ref_data
        end
      end
      @anomaly = result
    end

    def surfh2o(gp,dir)
      ps = gpopen dir+ "H2OLiq.nc"
      sig_weight = gpopen("/home/ishioka/link/all/omega1/data/H2OLiq.nc","sig_weight")
      gp = (gp * ps * sig_weight).sum("sig")/Grav 
      return gp
    end

    
    public
    attr_reader :list, :data_name, :anomaly
  end
  # -------------------------------------------
  def self.delt(gpa1,gpa2)
    result = []
    gpa1.anomaly.each_index{|n|
      gp1 = gpa1.anomaly[n]
      n2 = gpa2.list.name.index(gpa1.list.name[n])
      next if n2.nil?
      gp2 = gpa2.anomaly[n2]
      gp = gp2 - gp1
      result << gp
    }
    return result
  end
  # -------------------------------------------
  def self.lat_fig2(data,list,hash={}) # 緯度分布
    lc = 23
    vx = 0.82
    vy = 0.8
    list.dir.each_index do |n|
      # データの取得
      gp = data[n]
      
      # 高さ方向にデータがある場合は最下層を取り出す
      gp = gp.cut("sig"=>1) if gp.axnames.include?("sig")
      
      # 時間平均経度平均
      gp = gp.mean('time') if gp.axnames.include?("time")
      gp = gp.mean(0) if gp.axnames[0] != "lat"
      
      # 降水量の単位変換
      gp = Utiles_spe.wm2mmyr(gp) if gp.name.include?("Rain") 
      
      # 描画
      vy = vy - 0.025
      if n == 0 then
        lc = 13 if list.ref.nil?
        fig_opt = {'index'=>lc,'legend'=>false,'annotate'=>false}
        GGraph.line( gp ,true ,fig_opt.merge(hash))
        DCL.sgtxzv(vx+0.05,vy,list.name[n],0.015,0,-1,3)
        DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
      elsif n == list.refnum
        lc_ref = 13
        fig_opt = {'index'=>lc_ref}      
        GGraph.line( gp ,false ,fig_opt.merge(hash))
        DCL.sgtxzv(vx+0.05,vy,list.name[n],0.015,0,-1,3)
        DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc_ref)     
      else
        lc = lc + 10
        fig_opt = {'index'=>lc}      
        GGraph.line( gp ,false ,fig_opt.merge(hash))
        DCL.sgtxzv(vx+0.05,vy,list.name[n],0.015,0,-1,3)
        DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
      end 
    end
  end
  #---------------------------------------------
  def self.lonlat2(data,list,hash={}) #水平断面
    list.dir.each_index do |n|
      gp = data[n]
      next if gp.nil?
      
      # 時間平均
      gp = gp.mean("time") if gp.axnames.include?("time")
      
      # 高さ方向の次元をカット
      gp = gp.cut("sig"=>1) if gp.axnames.include?("sig")
      gp = gp.cut("sigm"=>1) if gp.axnames.include?("sigm")
      
      # 地方時を[degree]に変換
      gp = Omega.fix_axis_local(gp)
      # 描画
      xmax = 360
      GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
      GGraph.set_fig('window'=>[0,xmax,-90,90])
      
      if hash["add"]
        addtitle = hash["add"]
        hash.delete("add")
      else
        addtitle = ""
      end

      fig_opt = {'title'=>addtitle + gp.long_name + " " + list.name[n],
        'annotate'=>false,
        'color_bar'=>true}.merge(hash)
      GGraph.tone_and_contour gp ,true, fig_opt
    end
  end
  #------------------------------------------- 
  def self.merid2(data,list,hash={}) #水平断面
    if hash["add"]
      addtitle = hash["add"]
      hash.delete("add")
    else
      addtitle = ""
    end

    list.dir.each_index do |n|
      gp = data[n]
      next if gp.nil?
      
      # 時間平均
      gp = gp.mean("time") if gp.axnames.include?("time")
      
      # 経度平均
      gp = gp.mean("lon") if gp.axnames.include?("lon")
      gp = gp.mean("local") if gp.axnames.include?("local")
      
      # 描画
      GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
      GGraph.set_fig('window'=>[-90,90,nil,nil])
      

      fig_opt = {'title'=>addtitle + gp.long_name + " " + list.name[n],
        'annotate'=>false,
        'color_bar'=>true,
        'nlev'=>20}.merge(hash)
      GGraph.tone_and_contour gp ,true, fig_opt
    end
  end
  def self.fix_axis_local(gp)
    xcoord = gp.axis(0).to_gphys.val
    xmax = (xcoord[1]-xcoord[0])*xcoord.length
    a = 360/xmax
    local = gp.axis(0).pos * a
    local.units = "degree"
    gp.axis(0).set_pos(local)
    return gp
  end
end

