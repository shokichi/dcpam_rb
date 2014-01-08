#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# GPhysArrayオブジェクト
# 
require File.expand_path(File.dirname(__FILE__)+"/"+"utiles_spe.rb")
include Utiles_spe
include NumRu
include Math
include NMath

module AnalyDCPAM
  class GPhysArray
    def initialize(name,listfile)
      @@listfile = listfile
      if listfile.class == Explist
        @list = listfile
      else
        @list = Explist.new(listfile)
      end
      @name = name
      @data = get_data
      @legend = get_legend
    end

    def ref
      return self[@list.ref] 
    end

    def +(other_gpa)
      gp_ary = []
      if other_gpa.class == GPhysArray 
        self.data.each_index do |n|
          gp1 = self.data[n]
          gp2 = other_gpa[self.legend[n]]
          gp = nil if gp1.nil? or gp2.nil?
          gp = gp1 + gp2 unless gp.nil?
          gp_ary << gp
        end
      else
        gp2 = other_gpa
        self.data.each_index do |n|
          gp1 = self.data[n]
          gp = nil if gp1.nil?
          gp = gp1 + gp2 unless gp.nil?
          gp_ary << gp
        end
      end
      result = self.clone
      result.data = gp_ary
      return result
    end

    def -(other_gpa)
      if other_gpa.class == GPhysArray 
        gp_ary = []
        self.data.each_index do |n|
          gp1 = self.data[n]
          gp2 = other_gpa[self.legend[n]]
          gp = nil if gp1.nil? or gp2.nil?
          gp = gp1 - gp2 unless gp.nil?
          gp_ary << gp
        end
      else
        gp2 = other_gpa
        self.data.each_index do |n|
          gp1 = self.data[n]
          gp = nil if gp1.nil?
          gp = gp1 - gp2 unless gp.nil?
          gp_ary << gp
        end
      end
      result = self.clone
      result.data = gp_ary
      return result
    end

    def *(other_gpa)
      gp_ary = []
      if other_gpa.class == GPhysArray 
        self.data.each_index do |n|
          gp1 = self.data[n]
          gp2 = other_gpa[self.legend[n]]
          gp = nil if gp1.nil? or gp2.nil?
          gp = gp1 * gp2 unless gp.nil?
          gp_ary << gp
        end
      else
        gp2 = other_gpa
        self.data.each_index do |n|
          gp1 = self.data[n]
          gp = nil if gp1.nil?
          gp = gp1 * gp2 unless gp.nil?
          gp_ary << gp
        end
      end
      result = self.clone
      result.data = gp_ary
      return result
    end

    def /(other_gpa)
      gp_ary = []
      if other_gpa.class == GPhysArray 
        self.data.each_index do |n|
          gp1 = self.data[n]
          gp2 = other_gpa[self.legend[n]]
          gp = nil if gp1.nil? or gp2.nil?
          gp = gp1 / gp2 unless gp.nil?
          gp_ary << gp
        end
      else
        gp2 = other_gpa
        self.data.each_index do |n|
          gp1 = self.data[n]
          gp = nil if gp1.nil?
          gp = gp1 / gp2 unless gp.nil?
          gp_ary << gp
        end
      end
      result = self.clone
      result.data = gp_ary
      return result
    end

    def [](key)
      return @data[@legend.index(key)]
    end

    def []=(*arg)
      val = arg.pop
      key = arg[0]
      @data[@legend.index(key)] = val
      return 
    end

    def data=(ary)
      @data = ary
      self
    end

    def anomaly
      ary = []
      @data.each do |gp|
        if gp.nil?
          ary << -999
          next
        end
        ary << gp - self.ref
      end
      result = self.clone
      result.data = ary
      return result
    end

    def mean(*axis)
      result = self.clone
      @legend.each do |key|
        next if self[key].nil?
        result[key] = self[key].mean(*axis)
      end
      return result
    end

    def cut(range)
      result = self.clone
      @legend.each do |key|
        next if self[key].nil?
        result[key] = self[key].cut(range)
      end
      return result 
    end

    def axnames
      return @data[0].axnames
    end

    def correlation(other_gpa)
      rotation = []
      coef_ary = []
      self.data.each_index do |n|
        gp1 = self.data[n]
        gp2 = other_gpa[self.legend[n]]
        coef = nil if gp2.nil?
        coef = calc_correlat_coef(gp1,gp2) if !gp2.nil?
        rotation << omega_ratio(@legend[n])
        coef_ary << coef
p coef
      end
      coef_gp = Utiles_spe.array2gp(rotation,coef_ary)
      coef_gp.axis(0).pos.name = "rotation rate" 
      coef_gp.name = "correlation"
      coef_gp.long_name = "correlation coefficient"
      return coef_gp      
    end

    private
    def get_data
      result = []
      @list.dir.each do |dir|
        gp = gpopen dir + @name+".nc"
        result << gp
      end
      return result
    end

    def get_legend
      @list.name
    end

    public
    attr_reader :list,:name,:data,:legend
  end
end
