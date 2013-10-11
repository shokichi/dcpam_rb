#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 動画作成
# make animation
#

require 'numru/ggraph'
require 'numru/gphys'
include NumRu
include Math



def tone_draw(gp,name,figopt={})
  intval = 10
  gp.axis("time").length/intval.to_i.times do |n| 
    figopt["keep"] = true if n != 0
    GGraph.tone gp[false,n*intval], true, figopt
  end
end
def line_draw(gp,name,figopt={})
  intval = 10
  gp.axis("time").length/intval.to_i.times do |n| 
    figopt["keep"] = true if n != 0
    GGraph.tone gp[false,n*intval], true, figopt
  end
end

def convert_img(file) # 画像結合
  dt = 17.6
  dt = Delay if include?(Delay)
  Dir::mkdir("movie") if !Dir::entries("./").include?("movie")
  `mv dcl_*.png movie/`
  `mogrify -format gif movie/*.png`
  `convert -delay #{dt} movie/dcl_*.gif movie/#{filename}.gif`
  `rm movie/dcl_*.gif movie/dcl_*.png`
end

def make_movie(varname,list)
  if defined?(FigOpt)
    figopt = FigOpt
  else
    figopt = {"min"=>0,"max"=>2000,"nlev"=>40}
  end

  # DCL
  clrmp = 14  # カラーマップ
  DCL.sgscmn(clrmp)
  DCL::swlset('lwnd',false)
  #DCL.swpset('lalt',true) if save == false

  list.dir.each_index{|n|
    filename = varname+".nc"
    filename = FileName if defined?(FileName)
    gp = gpopen list.dir[n] + filename,varname
    next if gp.nil?
    gp = gp.cut("lat"=>0)
    # DCL
    DCL.gropn(4)
    DCL.sgpset('lcntl',false)
    #DCL.sgpset('lfull',true)
    DCL.uzfact(0.7)
    #DCL.sldiv('Y',1,2) 
    #DCL::gllset('LMISS', true)
    #DCL::glrget('RMISS')
    #rmiss = DCL.glpget('rmiss')

    # GGraph
    if defined?(Flag_line)
      line_draw(gp,name,figopt)
    else
      tone_draw(gp,name,figopt)
    end
    DCL.grcls
    ofilen = list.id+"_"+File.basename(__FILE__,".rb")+"_"+
                                    list.name[n]+"_"+varname
    convert_img(varname,list.dir[n],list.name[n])
    print "[#{varname}](#{listdir[n]})::#{__FILE__} is created\n"
  end
end

# option
opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-n VAR","--name=VAR") {|name|
  char = name.split("@")
  VarName = char[-1]
  FileName = char[0] if char.size == 2 }
opt.on("-o OPT","--figopt=OPT") {|hash| Figopt = hash}
opt.on("--line"){Flag_line = true}
opt.parse!(ARGV)

list = Utiles_spe::Explist.new(ARGV[0])
varname = "Rain"
varname = VarName if defined?(VarName)

make_movie(varname,list)

