#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 動画作成
# make animation
#
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/../lib/make_figure.rb")
require 'optparse'
include MKfig
include NumRu

#module MKanim
  def tone_draw(gp_ary,name,hr_in_day,figopt={})
    intval = 6*3
    intval = Skip.to_f if defined? Skip and !Skip.nil?

    (gp_ary[0].axis("time").length/intval).to_i.times do |n|       
      gp_ary.each_index do |n|
        if defined? Cut and !Cut.nil?
          gp = gp_ary[n].cut(Cut)
        else
          gp = gp_ary[n]
        end
        opt = {}
        opt["title"] = gp.name
        opt["keep"] = true if n != 0
        data = local_time(gp[false,n*intval..n*intval],hr_in_day)
        GGraph.tone data, true, figopt[n].merge(opt)
      end
    end
  end
  
  def line_draw(gp_ary,name,hr_in_day,figopt={})
    intval = Skip
    (gp_ary.axis("time").length/intval).to_i.times do |n| 
      figopt["keep"] = true if n != 0
      data = local_time(gp[false,n*intval..n*intval],hr_in_day)
      GGraph.tone data, true, figopt
    end
  end

  def contour_draw(gp)
  end
#end

def make_movie(varname,list)
  # DCL
  clrmp = 14  # カラーマップ
  DCL.sgscmn(clrmp)
  DCL::swlset('lwnd',false)

  figopt = set_figopt
  gp_ary = []
  varname = [varname] if varname.class != Array 
  list.dir.each_index do |n|

    varname.each{ |var| gp_ary << gpopen( list.dir[n]+var+".nc")}
    next if gp_ary.include? nil

    if defined? HrInDay
      hr_in_day =HrInDay
    else
      hr_in_day = 24 / omega_ratio(list.name[n])
      hr_in_day = 24 if list.id.include?("coriolis")
    end

    # DCL
    DCL.gropn(4)
    DCL.sgpset('lcntl',false)
    DCL.uzfact(0.7)
    if VarName.class == Array and VarName.length == 2 
      DCL.sgpset('lfull',true)
      DCL.sldiv('Y',1,2)
      GGraph.set_fig "viewport"=>[0.05,0.45,0.05,0.25]
    end
    #DCL.sldiv('Y',2,2) if VarName.length > 2
    #DCL::gllset('LMISS', true)
    #DCL::glrget('RMISS')
    #rmiss = DCL.glpget('rmiss')
    # 描画
      
    if FigType == "line"
      MKanim.line_draw(gp_ary,list.name[n],hr_in_day,figopt)
    elsif FigType == "contour"
      MKanim.contour_draw(gp_ary,list.name[n],hr_in_day,figopt)
    else 
      tone_draw(gp_ary,list.name[n],hr_in_day,figopt)
    end
    
    DCL.grcls
    
    ofilen = list.id+"_"+File.basename(__FILE__,".rb")+"_"+
                                          list.name[n]+"_"+varname.join("_")
    print "#{varname}(#{list.dir[n]})::#{__FILE__} is created\n"
  end
end


def cut_and_mean(gp)
  gp = gp[false,0..6*24*5]
  gp = gp.cut("sig"=>Sig) if defined?(Sig)
  gp = gp.cut("lat"=>0) if gp.axnames.include?("sig") or gp.axnames.include?("sigm")
  return gp
end

# option
opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-n VAR","--name=VAR") {|name|
  char = name.split("@")
  VarName = char[-1]
  FileName = char[0] if char.size == 2 }
opt.on("--local") {Flag_local = true}
opt.on("-h Num","--hr_in_day==Num") {|hrs| HrInDay = hrs.to_f}
opt.on("--max=max") {|max| Max = max.to_f}
opt.on("--min=min") {|min| Min = min.to_f}
opt.on("--nlev=nlevels") {|nlev| Nlev = nlev.to_f}
opt.on("--clr_max=color_max") {|max| ClrMax = max.to_f}
opt.on("--cr_min=color_min") {|min| ClrMin = min.to_f}
opt.on("--sig=sigma") {|sig| Sig = sig.to_f}
opt.on("--line"){Flag_line = true}
opt.on("--contour"){Flag_contour = true}
opt.parse!(ARGV)

#list = Utiles_spe::Explist.new(ARGV[0])

#varname = "Rain"
#varname = VarName if defined?(VarName)

#make_movie(VarName,list)

