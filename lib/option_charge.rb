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
      figure_parameter
      attribute_parameter
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
    def figure_parameter
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
      @@opt.on("--hr_in_day=[hours in day]") {
        |hrs| @charge[:hr_in_day] = hrs}
      @@opt.on("--omega=[rotation rate]") {
        |omega| @charge[:omega] = omega}
      @@opt.on("--time_range=Day") {|day| @charge[:timerange] = day.to_f}
    end
    
    def cut_and_mean
      @@opt.on("--lat=[latitude]") {|lat| @charge[:lat] = lat.to_f}
      @@opt.on("--cut=[cut range]"){|range| @charge[:cut] = range }
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
end
