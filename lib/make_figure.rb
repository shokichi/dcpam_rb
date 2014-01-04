#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 
# 
require "numru/ggraph"
require 'numru/gphys'
include NumRu
include Math
include NMath
require File.expand_path(File.dirname(__FILE__)+"/"+"utiles_spe.rb")
require File.expand_path(File.dirname(__FILE__)+"/gphys-ext_dcpam.rb")
include AnalyDCPAM
include Utiles_spe

module MKfig
  def make_figure(varname,list,type,figopt={})
    gpa = GPhysArray.new(varname,list)

    if !figopt[:type].nil?
      type = figopt[:type]
      figopt.delete(:type)
    end
    
    type = FigType if defined? FigType
    return if defined? type    

    case type 
      merid(gpa,figopt)
    when "lat"
      lat(gpa,figopt)
    when "lon"
      lon(gpa,figopt)
    when "merid"
      merid(gpa,figopt)
    when "lonsig"
      lonsig(gpa,figopt)
    when "lonlat"
      lonlat(gpa,figopt)
    when "lontime"
      lontime(gpa,figopt)
    end    

  end
# --------------------------------------------------  
  def set_dcl(clr=false)    # DCL set
    clrmp = 14  # カラーマップ
    DCL::swlset('lwnd',false) if IWS==4
    DCL.sgscmn(clrmp) if clr
    DCL.gropn(IWS)
    #DCL.sldiv('Y',2,1)
    DCL.sgpset('lcntl',true)
    DCL.sgpset('isub', 96)
    DCL.uzfact(1.0)
  end
# --------------------------------------------------  
  def merid(gpa,hash={}) # 子午面断面
    gpa = gpa.mean("time") if gpa.axnames.include?("time")
    gpa = gpa.mean("lon") if gpa.axnames.include?("lon")
      
    gpa.legend.each do |legend|
      next if gpa[legend].nil?
      gp = gpa[legend]
      if gp.max.to_f > 1e+10 then
        gp = gp*1e-10
        gp.units = "10^10 " + gp.units.to_s
      end
  
      fig_opt = {'color_bar'=>true,
                 'title'=>gp.long_name + " " + legend,
                 'annotate'=>false,
                 'nlev'=>20}.merge(hash)
      GGraph.tone_and_contour(gp, true,fig_opt)
    end
  end
#------------------------------------------------  
  def lat(gpa,hash={}) # 緯度分布
    # 高さ方向にデータがある場合は最下層を取り出す
    gpa = gpa.cut("sig"=>1) if gpa.axnames.include?("sig")
    # 時間平均経度平均
    gpa = gpa.mean('time') if gpa.axnames.include?("time")
    gpa = gpa.mean("lon") if gp.axnames.include?("lon")
  
    lc = 23
    vx = 0.82
    vy = 0.8
    gpa.legend.each do |legend|

      next if gpa[legend].nil?
      gp = gpa[legend]

      # 
      gp = gp.wm2mmyr if gp.name.include?("Rain") 
  
      # 描画
      vy = vy - 0.025
      if n == 0 then
        lc = 13 if list.ref.nil?
        fig_opt = {'index'=>lc,'legend'=>false,'annotate'=>false}
        GGraph.line( gp ,true ,fig_opt.merge(hash))
        DCL.sgtxzv(vx+0.05,vy,legend,0.015,0,-1,3)
        DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
      elsif n == list.refnum
        lc_ref = 13
        fig_opt = {'index'=>lc_ref}      
        GGraph.line( gp ,false ,fig_opt.merge(hash))
        DCL.sgtxzv(vx+0.05,vy,legend,0.015,0,-1,3)
        DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc_ref)     
      else
        lc = lc + 10
        fig_opt = {'index'=>lc}      
        GGraph.line( gp ,false ,fig_opt.merge(hash))
        DCL.sgtxzv(vx+0.05,vy,legend,0.015,0,-1,3)
        DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
      end 
    end
  end
#------------------------------------------------
  def lon(gpa,hash={})
    # 高さ方向にデータがある場合は最下層を取り出す
    gpa = gpa.cut("sig"=>1) if gpa.axnames.include?("sig")
    # 時間平均経度平均
    gpa = gpa.mean('time') if gpa.axnames.include?("time")
    # 緯度切り出し
    lat = 0
    lat = Lat if defined?(Lat)
    gp = gp.cut("lat"=>lat)

    lc = 23
    vx = 0.82
    vy = 0.8
    gpa.legend.each do |legend|
      next if gpa[legend].nil?
      gp = gpa[legend]
  
      # 降水量の単位変換
      gp = gp.wm2mmyr if gp.name.include?("Rain") 

      gp = fix_axis_local(gp)      
      # 描画
      xmax = 360
      GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
      GGraph.set_fig('window'=>[0,xmax,nil,nil])

      # 描画
      vy = vy - 0.025
      if n == 0 then
        lc = 13 if list.ref.nil?
        fig_opt = {'index'=>lc,'legend'=>false,'annotate'=>false}
        GGraph.line( gp ,true ,fig_opt.merge(hash))
        DCL.sgtxzv(vx+0.05,vy,legend,0.015,0,-1,3)
        DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
      elsif n == list.refnum
        lc_ref = 13
        fig_opt = {'index'=>lc_ref}      
        GGraph.line( gp ,false ,fig_opt.merge(hash))
        DCL.sgtxzv(vx+0.05,vy,legend,0.015,0,-1,3)
        DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc_ref)     
      else
        lc = lc + 10
        fig_opt = {'index'=>lc}      
        GGraph.line( gp ,false ,fig_opt.merge(hash))
        DCL.sgtxzv(vx+0.05,vy,legend,0.015,0,-1,3)
        DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
      end 
    end      
  end

# -----------------------------------------------
  def lonlat(var_name,list,hash={}) #水平断面
    # 高さ方向にデータがある場合は最下層を取り出す
    gpa = gpa.cut("sig"=>1) if gpa.axnames.include?("sig")
    gpa = gpa.cut("sigm"=>1) if gpa.axnames.include?("sigm")
    # 時間平均経度平均
    gpa = gpa.mean('time') if gpa.axnames.include?("time")

    gpa.legend.each do |legend|
      next if gpa[legend].nil?
      gp = gpa[legend]
   
      # 横軸最大値
      xcoord = gp.axis(0).to_gphys.val
      xmax = (xcoord[1]-xcoord[0])*xcoord.length
  
      # 描画
      GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
      GGraph.set_fig('window'=>[0,xmax,-90,90])
  
      fig_opt = {'title'=>gp.long_name + " " + legend,
                 'annotate'=>false,
                 'color_bar'=>true}.merge(hash)
      GGraph.tone_and_contour gp ,true, fig_opt
    end
  end
#---------------------------------------------
  def lonsig(var_name,list,hash={}) # 経度断面
    # 時間平均経度平均
    gpa = gpa.mean('time') if gpa.axnames.include?("time")

    # 緯度切り出し
    lat = 0
    lat = Lat if defined?(Lat)
    gpa = gpa.cut("lat"=>lat)

    gpa.legend.each do |legend|
      next if gpa[legend].nil?
      gp = gpa[legend]

      # 横軸最大値
      gp = fix_axis_local(gp)
      xmax = 360
      # 描画
      GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
      GGraph.set_fig('window'=>[0,xmax,nil,nil])
  
      fig_opt = {'title'=>gp.long_name + " " + legend,
                 'annotate'=>false,
                 'color_bar'=>true}.merge(hash)
      GGraph.tone_and_contour gp ,true, fig_opt
    end
  end
# -------------------------------------------
  def lontime(varname,list,hash={})
    # 時間軸確認
    return if !gpa.axnames.include?("time")

    # 鉛直切り出し
    gpa = gpa.cut("sig"=>1) if gpa.axnames.include?("sig")
    # 緯度切り出し
    lat = 0
    lat = Lat if defined?(Lat)
    gpa = gpa.cut("lat"=>lat)

    gpa.legend.each do |legend|
      next if gpa[legend].nil?
      gp = gpa[legend]

      # Use time:30 days, Intervel: 1/24 hours

      if defined? HrInDay 
        hr_in_day = HrInDay
      else
        hr_in_day = 24/omega_ratio(legend)
      end
      hr_in_day = 24 if gpa.list.id.include? "coriolis"

      # 時間切り出し
      time = gp.axis("time").pos
      range = 30  # [day]
      range = TimeRange if defined? TimeRange
      strtime = time[0].val
      if time.units.to_s == "hrs"
        endtime = strtime + range*hr_in_day
      elsif time.units.to_s == "min"
        endtime = strtime + range*hr_in_day*60
      else
        endtime = strtime + range
      end
#      gp = gp.cut("time"=>strtime..endtime)
      gp = gp[false,0..30*24*6]
      # 1/24日毎のデータ切り出し
#      skip = 1.0/24    # [day]
#      gp = skip_time(gp,skip,hr_in_day)
      gp = skip_num(gp,6)

      # 横軸最大値
#      gp = fix_axis_local(gp)
      xmax = 360

      # 描画
      GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
      GGraph.set_fig('window'=>[0,xmax,nil,nil])
  
      fig_opt = {'title'=>gp.long_name + " " + legend,
                 'annotate'=>false,
                 'color_bar'=>true}.merge(hash)
      GGraph.tone gp ,true, fig_opt
    end
  end
  # -------------------------------------------
#   def gave_netrad(dir,name)  # エネルギー収支の確認
#     # データの取得
#     begin
#       osr = GPhys::IO.open(dir + "OSRA.nc","OSRA")
#       olr = GPhys::IO.open(dir + "OLRA.nc","OLRA")
#     rescue
#       print "[OSR,OLR](#{dir}) is not exist\n"
#       next
#     end
#     # 全球平均
#     if osr.rank != 1 then
#       osr = Utiles_spe.glmean(osr)
#       olr = Utiles_spe.glmean(olr)
#     end
#     # 描画
#     GGraph.line osr+olr,true,'title'=>'OSR+OLR '+name
#   end
#   # -------------------------------------------
#   def gave_AM(dir,name)  # エネルギー収支の確認
#     # データの取得
#     begin
#       am = GPhys::IO.open(dir + "AnglMom.nc","AnglMom")
#       ps = GPhys::IO.open(dir + "Ps.nc","Ps")
#     rescue
#       print "[AnglMon](#{dir}) is not exist\n"
#     next
#     end
#     
#     # 全球平均
#     am = Utiles_spe.virtical_integral(Utiles_spe.glmean(am*ps)) if am.rank !=1
#     
#     # 描画
#     GGraph.line am, true, 'title'=>'AnglMom '+name
#   end
  # -------------------------------------------
  def self.cut_and_mean(gp)
    eval "gp = gp.cut(#{Opt.charge[:cut]})" if defined? Opt.charge[:cut]
    eval "gp = gp.cut(#{Opt.charge[:mean]})" if defined? Opt.charge[:mean]
    return gp
  end
  # -------------------------------------------
  def fix_axis_local(gp)
    xcoord = gp.axis(0).to_gphys.val
    xmax = (xcoord[1]-xcoord[0])*xcoord.length
    return gp if xmax == 360
    a = 360/xmax
    local = gp.axis(0).pos * a
    local.units = "degree"
    gp.axis(0).set_pos(local)
    return gp
  end
# -------------------------------------------
  def set_figopt
    figopt = {}
    figopt["max"] = Max if defined?(Max)
    figopt["min"] = Min if defined?(Min)
    figopt["nlev"] = Nlev if defined?(Nlev)
    figopt["clr_max"] = ClrMax if defined?(ClrMax)
    figopt["clr_min"] = ClrMin if defined?(ClrMin)        
    figopt = parse_Figopt(figopt)
    return figopt
  end
# -------------------------------------------
  def parse_Figopt(figopt)
    return figopt if !defined? Figopt
    if Figopt.class == Array
      result = []
      Figopt.each{|hash| result << hash.merge(figopt)}
    else
      result = Figopt.merge(figopt)
    end
    return result
  end
# -------------------------------------------
  def rename_img_file(id,scrfile) 
    id = id.id if id.class == Explist
    img_lg = id+File.basename(scrfile,".rb").sub("mkfig","")
    img_lg += "_lat#{Lat.to_i}" if defined?(Lat)
    img_lg += "_#{VarName}" if defined?(VarName)
    if IWS == 2 
      File.rename("dcl.ps","#{img_lg}.ps")
    elsif IWS == 4
      Dir.glob("dcl_*.png").each{ |filename|
        File.rename(filename,filename.sub("dcl",img_lg)) }
    end
  end  
end
