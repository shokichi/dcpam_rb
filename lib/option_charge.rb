#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# オプション管理
#
#
module OptCharge
  require 'optparse'

  class OptCharge
 
    def initialize(arge)
      @@arge = arge
      @@opt = OptionParser.new
      @charge = {}
      figure_parameter
      attribute_parameter
      picture_format
      cut_and_mean
    end
    
    def set
      @@opt.parse!(@@arge)
    end
    
    def add_option(arg,option,format=nil)
      @@opt.on(arg) {|v| 
        v = v.to_f if format == "float"
        @charge[option] = v 
      }
    end
    
    private
    def figure_parameter
      @@opt.on("--max=[maximum]") {|max| @charge[:max] = max.to_f}
      @@opt.on("--min=[minimum]") {|min| @charge[:min] = min.to_f}
      @@opt.on("--nlev=[number of levels]") {
        |nlev| @charge[:nlev] = nlev.to_i}
      @@opt.on("--clr_max=[maximum color id]") {
        |id| @charge[:clrmax] = id.to_i}
      @@opt.on("--clr_min=[minimum color id]") {
        |id| @charge[:clrmin] = id.to_i}
      @@opt.on("--notitle") {@charge[:notitle] = true}
    end
    
    def attribute_parameter
     @@opt.on("-r","--rank") {@charge[:rank] = true}
      @@opt.on("--name=[data name]") {|name| @charge[:varname] = name}
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
    end
    
    def picture_format
      @@opt.on("--parafig=[number of picture]"){
        |num| @charge[:parafig] = num.to_i }
      @@opt.on("--eps") {@charge[:eps] = true} 
      @@opt.on("--ps")  {@charge[:ps]  = true}
      @@opt.on("--png") {@charge[:png] = true}
    end
    
    public
    attr_reader :charge
  end
end
