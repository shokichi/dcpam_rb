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
      @@opt.on("--max=MAX") {|max| @charge[:max] = max.to_f}
      @@opt.on("--min=MIN") {|min| @charge[:min] = min.to_f}
      @@opt.on("--nlev=nlevel") {|nlev| @charge[:nlev] = nlev.to_i}
      @@opt.on("--clr_max=color_max") {|clrmax| @charge[:clrmax] = clrmax.to_i}
      @@opt.on("--clr_min=color_min") {|clrmin| @charge[:clrmin] = clrmin.to_i}
      @@opt.on("--notitle") {@charge[:notitle] = true}
    end
    
    def attribute_parameter
     @@opt.on("-r","--rank") {@charge[:rank] = true}
      @@opt.on("--name=STRING") {|name| @charge[:varname] = name}
      @@opt.on("--hr_in_day=Float") {|hrs| @charge[:hr_in_day] = hrs}
      @@opt.on("--omega=Float") {|omega| @charge[:omega] = omega}
    end
    
    def cut_and_mean
      @@opt.on("--cut=STRING"){|range| @charge[:cut] = range }
      @@opt.on("--mean=STRING"){|axis| @charge[:mean] = axis }
    end
    
    def picture_format
      @@opt.on("--eps") {@charge[:eps] = true} 
      @@opt.on("--ps")  {@charge[:ps]  = true}
      @@opt.on("--png") {@charge[:png] = true}
    end
    
    public
    attr_reader :charge
  end
end
