#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# オプション管理
#
#
module OptCharge
  require 'optparse'
  class OptCharge
 
    def initialize(arge=ARGV)
      @@arge = arge
      @@opt = OptionParser.new
      @charge = {}
      ggraph_parameter
      attribute_parameter
      rotation_rate
      picture_format
      cut_and_mean
      self
    end
    
    def set
      @@opt.parse!(@@arge)
    end
    
    def add_option(arg,option,format=nil)
      @@opt.on(arg) {|v| 
        v = v.to_f if format == "float"
        v = true if format == "flag"
        @charge[option] = v 
      }
    end
    
    private
    def ggraph_parameter
      @@opt.on("--max=[maximum]") {|max| @charge[:max] = max.to_f}
      @@opt.on("--min=[minimum]") {|min| @charge[:min] = min.to_f}
      @@opt.on("--nlev=[number of levels]") {
        |nlev| @charge[:nlev] = nlev.to_i}
      @@opt.on("--interval=[contour interval]") {
        |nlev| @charge[:interval] = nlev.to_i}
      @@opt.on("--clr_max=[maximum color id]") {
        |id| @charge[:clr_max] = id.to_i}
      @@opt.on("--clr_min=[minimum color id]") {
        |id| @charge[:clr_min] = id.to_i}
      @@opt.on("--notitle") {@charge[:notitle] = true}
      @@opt.on("--nolegend") {@charge[:nolegend] = true}
      @@opt.on("--xmin=[x axis minimum]"){|min| @charge[:xmin] = min.to_f}
      @@opt.on("--xmax=[x axis maximum]"){|max| @charge[:xmax] = max.to_f}
      @@opt.on("--ymin=[y axis minimum]"){|min| @charge[:ymin] = min.to_f}
      @@opt.on("--ymax=[y axis maximum]"){|max| @charge[:ymax] = max.to_f}
    end
    
    def attribute_parameter
      @@opt.on("-r","--rank") {@charge[:rank] = true}
      @@opt.on("--name=[data name]") {|name| @charge[:name] = name}
    end

    def rotation_rate
      @@opt.on("--hr_in_day=[hours in day]") {
        |hrs| @charge[:hr_in_day] = hrs}
      @@opt.on("--omega=[rotation rate]") {
        |omega| @charge[:omega] = omega}
    end
    
    def cut_and_mean
      @@opt.on("--lat=[latitude range]"){|lat| @charge[:lat] = lat.to_range}
      @@opt.on("--lon=[latitude range]"){|lon| @charge[:lon] = lon.to_range}
      @@opt.on("--time=[time range]"){|time| @charge[:time] = time.to_range}
      @@opt.on("--mean=[mean axis]"){|axis| @charge[:mean] = axis }
      @@opt.on("--latmean"){@charge[:latmean] = true }
      @@opt.on("--anomaly"){@charge[:anomaly] = true }
    end
    
    def picture_format
      @@opt.on("--delete=[delete exp]"){
        |legend| @charge[:delete] = legend }
      @@opt.on("--parafig=[number of picture]"){
        |num| @charge[:parafig] = num.to_i }
      @@opt.on("--print_ident"){@charge[:print_ident] = true}
      @@opt.on("--iheight=[DCL iheight]"){
        |num| @charge[:iheight] = num.to_i }
      @@opt.on("--iwidth=[DCL iwidth]"){
        |num| @charge[:iwidth] = num.to_i }
      @@opt.on("--eps") {@charge[:eps] = true} 
      @@opt.on("--ps")  {@charge[:ps]  = true}
      @@opt.on("--png") {@charge[:png] = true}
    end
    public
    attr_reader :charge
  end
  # --------------------------------------------------- 
  class String
    def to_range # String -> Range
      str = self.clone
      first, last = str.split("..")
      return first.to_f if last.nil?
      result = Range.new(first.to_f,last.to_f)
      return result
    end
  end
end
