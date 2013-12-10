#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Global average

require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/lib/make_figure.rb")
require 'optparse'
include MKfig
include NumRu

def create_gave(list)
  # データ
  dataset = gave_dataset
  # ファイル作成 
  file_path = "#{list.id}_global-ave.dat"
  file_prit(file_path,dataset)
end

def gave_dataset(list,varlist)
  ary = []
  data = rotation_rate_data(list)
  varlist.each do |varname|
    list.dir.each do |dir|
      ary << global_mean_data(varname,dir)  
    end
    data[varname] = ary
  end
end

def rotation_rate_data(list)
  omega = []
  list.name.each do |name|
    omega << Utiles_spe.omega_ratio(name)
  end
  return {"Rotaion"=>omega}
end

def gloval_mean_date(varname,dir)
  # データの取得
  gp = gpopen dir + varname
  return "None" if gp.nil?
  
  # 大気最下層切り出し
  gp = gp.cut("sig"=>1) if gp.axnames.include?("sig")
  gp = gp.cut("sigm"=>1) if gp.axnames.include?("sigm")
  
  # 降水量の単位変換
  gp = Utiles_spe.wm2mmyr(gp) if var_name.include? "Rain"

  # 全球平均
  result = Utiles_spe.glmean(gp) if gp.rank != 1  
  return result
end

def file_print(file_path,data)
  File.open(file_path) do |file|
    # ファイル出力
    file.print "##########################\n"
    file.print "# 全球平均値              \n"
    file.print "##########################\n"
    data.keys.each do |varname|
      file.print varname, "\t"
      file.print data[varname].join("\t") ,"\n"
    end
  end
  puts "#{file_path} created\n"
end

# 実行
list = Utiles_spe::Explist.new(ARGV[0])
varlist = ['OSRA','OLRA',
           'SSRA','SLRA','EvapA','SensA',
           'SurfTemp','Temp',
           'Rain','RainCumulus','RainLsc',
           'PrcWtr',
           'RadSUWFLXA','RadSDWFLXA',
           'RadLUWFLXA','RadLDWFLXA']

create_gave(list,varlist)
