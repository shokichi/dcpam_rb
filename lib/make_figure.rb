#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 
# 
=begin

== Module Function
--- make_figure
--- make_figure(varname,list,figopt)
--- set_dcl(clr=false)
--- plural_picture(amount)
--- merid(gpa,option)
--- lat(gpa,option)
--- lon(gpa,option) 
--- lonlat(gpa,option)
--- lonsig(gpa,option)
--- lontime(gpa,option)
--- plot(y_coord,newframe=true,option)
--- self.cut_and_mean(gp)
--- fix_axis_local(gp)
--- get_iws
--- set_figopt
--- set_window(window)
--- option_notice?(key)
--- parse_Figopt(figopt)
--- rename_img_file(id,scrfile) 
=end



require "numru/ggraph"
require 'numru/gphys'
include NumRu
include Math
include NMath
require File.expand_path(File.dirname(__FILE__)+"/option_charge.rb")
require File.expand_path(File.dirname(__FILE__)+"/utiles.rb")
require File.expand_path(File.dirname(__FILE__)+"/gphys-ext_dcpam.rb")
require File.expand_path(File.dirname(__FILE__)+"/gphys_array.rb")
include AnalyDCPAM
include Utiles


module MKfig
  def make_figure(varname,list,figopt={})

    if !figopt[:figtype].nil?
      type = figopt[:figtype]
      figopt.delete(:figtype)
    end
    type = FigType if defined? FigType
    return if !defined? type    

    gpa = gpaopen varname,list

    gpa = gpa.anomaly if option_notice?(:anomaly)
    gpa = gpa.delete(Opt.charge[:delete]) if option_notice?(:delete)
    gpa = cut_axes(gpa) if type != "time"

    case type 
    when "lat"
      lat(gpa,figopt)
    when "lon"
      lon(gpa,figopt)
    when "time"
      time(gpa,figopt)
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
  def set_dcl(clr=nil) # DCL set
    iwidth = 700 
    iheight = 700
    iwidth = Opt.charge[:iwidth] if option_notice?(:iwidth)
    iheight = Opt.charge[:iheight] if option_notice?(:iheight)
    DCL::swlset('lwnd',false) if IWS==4
    DCL.sgscmn(clr) if !clr.nil?
    DCL.swpset('iwidth',iwidth)
    DCL.swpset('iheight',iheight)
    DCL.gropn(IWS)
    DCL.sgpset('lcntl',true)
    DCL.sgpset('isub', 96)
    DCL.uzfact(1.0)
    plural_picture(Opt.charge[:parafig]) if defined? Opt
  end
  # --------------------------------------------------
  def plural_picture(amount)
    return if amount.nil?
    yoko = 2
    tate = (amount.to_i+1)/2
    yoko = 3 if amount == 3
    tate = 1 if amount <= 3
    DCL.sldiv('T',yoko,tate) 
#    DCL.sgpset('lcntl', false)   # 制御文字を解釈しない
    DCL.sgpset('lfull',false)     # 全画面表示
  end
  # --------------------------------------------------  
  def merid(gpa,hash={}) # 子午面断面

    gpa = gpa.mean("lon") if gpa.axnames.include?("lon")
    gpa = gpa.mean("time") if gpa.axnames.include?("time")

    GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
    GGraph.set_fig('window'=>set_window([-90,90,nil,nil]))

    n = 0
    gpa.legend.each do |legend|
      next if gpa[legend].nil?
      gp = gpa[legend]
      if gp.max.to_f > 1e+9 then
        gp = gp*1e-10
        gp.units = "10^10 " + gp.units.to_s
      end

      fig_opt = {'color_bar'=>true,
                 'title'=>gp.long_name + " " + legend,
                 'annotate'=>false,
                 'nlev'=>20}.merge(hash)
      GGraph.tone_and_contour(gp, true,fig_opt)
      print_identifier(n)
      n += 1
    end
  end
  #------------------------------------------------  
  def lat(gpa,hash={}) # 緯度分布
    # 高さ方向にデータがある場合は最下層を取り出す
    gpa = gpa.cut("sig"=>1) if gpa.axnames.include?("sig")
    # 時間平均経度平均
    gpa = gpa.mean('time') if gpa.axnames.include?("time")
    gpa = gpa.mean("lon") if gpa.axnames.include?("lon")

    lc = 23
    vx = 0.82
    vy = 0.8
    gpa.legend.each_index do |n|
      legend = gpa.legend[n]
      gp = gpa[legend]
      next if gp.nil?  
      GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
      GGraph.set_fig('window'=>set_window([-90,90,nil,nil]))

      # 
      gp = gp.wm2mmyr if gp.name.include?("Rain") 
  
      # 描画
      vy = vy - 0.025
      if n == 0 then
        lc = 13 if gpa.list.ref.nil?
        fig_opt = {'index'=>lc,'legend'=>false,'annotate'=>false}
        GGraph.line( gp ,true ,fig_opt.merge(hash))
        DCL.sgtxzv(vx+0.05,vy,legend,0.015,0,-1,3)
        DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
      elsif n == gpa.list.refnum
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
    gpa = gpa.cut("sig"=>1) if gpa.axnames.include?("sig") #最下層切り出し
    gpa = gpa.mean('time') if gpa.axnames.include?("time") #時間平均
    # 緯度切り出し
    gpa = gpa.latmean if option_notice?(:latmean)
    if gpa.axnames.include?("lat")
      lat = 0
      lat = Lat if defined?(Lat)
      lat = Opt.charge[:lat] if option_notice?(:lat)
      gpa = gpa.cut("lat"=>lat)
    end

    lc = 23
    vx = 0.82
    vy = 0.8
    gpa.legend.each_index do |n|
      legend = gpa.legend[n]
      gp = gpa[legend]
      next if gp.nil?  

      gp = gp.wm2mmyr if gp.name.include?("Rain") 

      gp = fix_axis_local(gp)      
      xmax = 360
      GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
      GGraph.set_fig('window'=>set_window([0,xmax,nil,nil]))

      # 描画
      vy = vy - 0.025
      if n == 0 then
        lc = 13 if gpa.list.ref.nil?
        fig_opt = {'index'=>lc,'legend'=>false,'annotate'=>false}
        GGraph.line( gp ,true ,fig_opt.merge(hash))
        DCL.sgtxzv(vx+0.05,vy,legend,0.015,0,-1,3)
        DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
      elsif n == gpa.list.refnum
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
# ------------------------------------------------------
  def time(gpa,hash={}) 
    gpa = gpa.cut("sig"=>1) if gpa.axnames.include?("sig")#最下層切り出し
    gpa = gpa.glmean
 
    lc = 23
    vx = 0.82
    vy = 0.8
    gpa.legend.each_index do |n|
      legend = gpa.legend[n]
      gp = gpa[legend]
      next if gp.nil?  

      gp = gp.wm2mmyr if gp.name.include?("Rain") 

      # 描画
      vy = vy - 0.025
      if n == 0 then
        lc = 13 if gpa.list.ref.nil?
        fig_opt = {'index'=>lc,'legend'=>false,'annotate'=>false}
        GGraph.line( gp ,true ,fig_opt.merge(hash))
        DCL.sgtxzv(vx+0.05,vy,legend,0.015,0,-1,3)
        DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
      elsif n == gpa.list.refnum
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
  def lonlat(gpa,hash={}) #水平断面
    # 高さ方向にデータがある場合は最下層を取り出す
    gpa = gpa.cut("sig"=>1) if gpa.axnames.include?("sig")
    gpa = gpa.cut("sigm"=>1) if gpa.axnames.include?("sigm")
    # 時間平均経度平均
    gpa = gpa.mean('time') if gpa.axnames.include?("time")

    n = 0
    gpa.legend.each do |legend|
      next if gpa[legend].nil?
      gp = gpa[legend]
   
      # 横軸最大値
      gp = fix_axis_local(gp)      
  
      # 描画
      GGraph.set_axes("xlabelint"=>90,"ylabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
      GGraph.set_fig('window'=>set_window([0,360,-90,90]))
  
      fig_opt = {'title'=>gp.long_name + " " + legend,
                 'annotate'=>false,
                 'color_bar'=>true}.merge(hash)
      GGraph.tone_and_contour gp ,true, fig_opt
      print_identifier(n)
      n += 1
    end
  end
#---------------------------------------------
  def lonsig(gpa,hash={}) # 経度断面
    # 時間平均経度平均
    gpa = gpa.mean('time') if gpa.axnames.include?("time")

    # 緯度切り出し
    lat = 0
    lat = Lat if defined?(Lat)
    lat = Opt.charge[:lat] if option_notice?(:lat)
    gpa = gpa.cut("lat"=>lat)

    n = 0
    gpa.legend.each do |legend|
      next if gpa[legend].nil?
      gp = gpa[legend]

      # 横軸最大値
      gp = fix_axis_local(gp)
      xmax = 360
      # 描画
      GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
      GGraph.set_fig('window'=>set_window([0,xmax,nil,nil]))
  
      fig_opt = {'title'=>gp.long_name + " " + legend,
                 'annotate'=>false,
                 'color_bar'=>true}.merge(hash)
      GGraph.tone_and_contour gp ,true, fig_opt
      print_identifier(n)
      n += 1
    end
  end

# -------------------------------------------
  def lontime(gpa,hash={})
    return if !gpa.axnames.include?("time")

    gpa = gpa.cut("sig"=>1) if gpa.axnames.include?("sig")

    lat = 0
    lat = Lat if defined?(Lat)
    lat = Opt.charge[:lat] if option_notice?(:lat)
    gpa = gpa.cut("lat"=>lat)
    n = 0
    gpa.legend.each do |legend|
      next if gpa[legend].nil?
      gp = gpa[legend]

      # Use time:30 days, Intervel: 1/24 hours

      ##############################################
      if defined? HrInDay 
        hr_in_day = HrInDay
      else
        hr_in_day = 24/omega_ratio(legend)
      end
      hr_in_day = 24 if gpa.list.id.include? "coriolis"
      ##############################################
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
      gp = gp.min2hrs
      # 描画
      GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
      GGraph.set_fig('window'=>[0,xmax,nil,nil])
  
      fig_opt = {'title'=>gp.long_name + " " + legend,
                 'annotate'=>false,
                 'color_bar'=>true}.merge(hash)
      GGraph.tone gp ,true, fig_opt
      print_identifier(n)
      n += 1
    end
  end
  # -------------------------------------------
  def time(gpa,hash={})
    gpa = gpa.cut("sig"=>1) if gpa.axnames.include?("sig") 

    n = 0
    lc = 23
    vx = 0.82
    vy = 0.8
    gpa.legend.each_index do |n|
      legend = gpa.legend[n]
      gp = gpa[legend]
      next if gp.nil?
      gp = gp.glmean
      # 降水量の単位変換
      gp = gp.wm2mmyr if gp.name.include?("Rain") 

      # 描画
      vy = vy - 0.025
      if n == 0 then
        lc = 13 if gpa.list.ref.nil?
        fig_opt = {'index'=>lc,'legend'=>false,'annotate'=>false}
        GGraph.line( gp ,true ,fig_opt.merge(hash))
        DCL.sgtxzv(vx+0.05,vy,legend,0.015,0,-1,3)
        DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
      elsif n == gpa.list.refnum
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
      print_identifier(n)
      n += 1 
    end          
  end
  # -------------------------------------------
  def plot(y_coord,newframe=true,hash={})
    x_coord = y_coord.axis(0).to_gphys
    y_coord.length.times do |n|
      figopt ={"index"=>index+10-2,"size"=>0.015,"type"=>4}.merge(hash)
      GGraph.scatter x_coord[n..n],gp[n..n],newframe,figopt
    end
  end
  # -------------------------------------------
  def cut_axes(gp)
    gp = gp.cut("lon"=>Opt.charge[:lon]) if option_notice?(:lon)
    gp = gp.cut("lat"=>Opt.charge[:lat]) if option_notice?(:lat)
    gp = gp.cut("time"=>Opt.charge[:time]) if option_notice?(:time)
#    eval "gp = gp.cut(#{Opt.charge[:cut])" if option_notice?(:cut)
#    eval "gp = gp.cut(#{Opt.charge[:mean])" if option_notice?(:mean)
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
  def print_identifier(n=0)
    return if !option_notice?(:print_ident)
    ident = ("a".."z").to_a
    DCL.sgtxzv(0.45,0.05,"(#{ident[n.to_i]})",0.035,0,-1,3)
  end
  # -------------------------------------------
  def get_iws
    if defined? Opt
      return 2 if Opt.charge[:ps] || Opt.charge[:eps]
      return 4 if Opt.charge[:png]
    end
    return 1 if !defined? IWS
  end
  # -------------------------------------------
  def set_figopt
    figopt = {}
    figopt["max"] = Opt.charge[:max] if option_notice?(:max)
    figopt["min"] = Opt.charge[:min] if option_notice?(:min)
    figopt["nlev"] = Opt.charge[:nlev] if option_notice?(:nlev)
    figopt["interval"] = Opt.charge[:interval] if option_notice?(:interval)
    figopt["clr_max"] = Opt.charge[:clr_max] if option_notice?(:clr_max)
    figopt["clr_min"] = Opt.charge[:clr_min] if option_notice?(:clr_min)
    figopt["title"] = "" if option_notice?(:notitle) 
    figopt = parse_Figopt(figopt)
    return figopt
  end
  # -------------------------------------------
  def set_window(window=[nil,nil,nil,nil])
    window[0] = Opt.charge[:xmin] if option_notice?(:xmin) 
    window[1] = Opt.charge[:xmax] if option_notice?(:xmax)
    window[2] = Opt.charge[:ymin] if option_notice?(:ymin) 
    window[3] = Opt.charge[:ymax] if option_notice?(:ymax)
    return window
  end
  # -------------------------------------------
  def option_notice?(key)
    if defined? Opt
      return !Opt.charge[key].nil?
    else
      return false
    end
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
  def convert_eps(psfile)
    begin
      require File.expand_path(File.dirname(__FILE__)+"/postscript.rb")
      include PostScript
      convert_ps2eps(psfile)
    rescue
      puts "*** Can't convert ps to eps ***"
    end
  end
  # -------------------------------------------
  def rename_img_file(id,scrfile) 
    return if IWS == 1
    id = id.id if id.class == Explist
    img_lg = id+"_"+File.basename(scrfile,".rb").sub("mkfig_","")
    img_lg += "_lat#{Opt.charge[:lat].to_i}" if option_notice?(:lat)
    img_lg += "_#{Opt.charge[:name]}" if option_notice?(:name)
    img_lg += "_anomaly" if option_notice?(:anomaly)
    if IWS == 2 
      File.rename("dcl.ps","#{img_lg}.ps")
      convert_eps("#{img_lg}.ps") if option_notice?(:eps)
    elsif IWS == 4
      Dir.glob("dcl_*.png").each{ |filename|
        File.rename(filename,filename.sub("dcl",img_lg)) }
    end
  end 
end

module MKfig
end
