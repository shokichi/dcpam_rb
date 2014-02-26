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
    def initialize(name=nil,listfile=nil)
      if listfile.class == Explist
        @list = listfile
      else
        @list = Explist.new(listfile)
      end
      @name = name
      @data = get_data
      @legend = get_legend
    end

    def self.create(array_of_gphys,legends)
      array_of_gphys = [array_of_gphys] if array_of_gphys.class != Array
      legends = [legends] if legends.class != Array

      if array_of_gphys.size != legends.size
        puts "Argument array size is not agreement"
        return 
      end
      gpa = self.new
      gpa.name = array_of_gphys[0].name
      gpa.data = array_of_gphys
      gpa.legend = legends
      return gpa
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
          if gp1.nil? or gp2.nil?
            gp_ary << nil 
          else
            gp_ary << gp1 + gp2
          end 
        end
      else
        gp2 = other_gpa
        self.data.each_index do |n|
          gp1 = self.data[n]
          gp_ary << gp1 + gp2
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
          if gp1.nil? or gp2.nil?
            gp_ary << nil 
          else
            gp_ary << gp1 - gp2
          end 
        end
      else
        gp2 = other_gpa
        self.data.each_index do |n|
          gp1 = self.data[n]
          gp_ary << gp1 - gp2
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
          if gp1.nil? or gp2.nil?
            gp_ary << nil 
          else
            gp_ary << gp1 * gp2
          end 
        end
      else
        gp2 = other_gpa
        self.data.each_index do |n|
          gp1 = self.data[n]
          gp_ary << gp1 * gp2           
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
          if gp1.nil? or gp2.nil?
            gp_ary << nil 
          else
            gp_ary << gp1 / gp2
          end 
        end
      else
        gp2 = other_gpa
        self.data.each_index do |n|
          gp1 = self.data[n]
          gp_ary << gp1 / gp2 
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

    def name=(str)
      @data = str
      self
    end

    def data=(ary)
      @data = ary
      self
    end

    def legend=(ary)
      @legend = ary
      self
    end

    def delete(*legends)
      legends = [legends] if legends.class != Array
      legends.each do |legend|
        @data.delete_at(@legend.index(legend))
        @legend.delete_at(@legend.index(legend))
      end
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
        result[key] = result[key].mean(*axis)
      end
      return result
    end

    def cut(range)
      result = self.clone
      @legend.each do |key|
        next if self[key].nil?
        result[key] = result[key].cut(range)
      end
      return result 
    end

    def glmean
      result = self.clone
      @legend.each do |key|
        next if self[key].nil?
        result[key] = result[key].glmean
      end
      return result
    end

    def latmean
      result = self.clone
      @legend.each do |key|
        next if self[key].nil?
        result[key] = result[key].latmean
      end
      return result
    end

    def axnames
      @data.each do |data|
        next if data.nil?
        return data.axnames
      end
      nil
    end

    def correlation(other_gpa) # omega
      rotation = []
      coef_ary = []
      self.data.each_index do |n|
        gp1 = self.data[n]
        gp2 = other_gpa[self.legend[n]]
        coef = nil if gp2.nil?
        coef = calc_correlat_coef(gp1,gp2) if !gp2.nil?
        rotation << omega_ratio(@legend[n])
        coef_ary << coef
      end
      coef_gp = Utiles_spe.array2gp(rotation,coef_ary)
      coef_gp.axis(0).pos.name = "rotation rate" 
      coef_gp.axis(0).pos.long_name = "Normalized rotation rate" 
      coef_gp.name = "correlation"
      coef_gp.long_name = "correlation coefficient"
      return coef_gp      
    end

    def regression(other_gpa) # omega
      rotation = []
      coef_ary = []
      self.data.each_index do |n|
        gp1 = self.data[n]
        gp2 = other_gpa[self.legend[n]]
        coef = nil if gp2.nil?
        coef = calc_regression_coef(gp1,gp2) if !gp2.nil?
        rotation << omega_ratio(@legend[n])
        coef_ary << coef
      end
      coef_gp = Utiles_spe.array2gp(rotation,coef_ary)
      coef_gp.axis(0).pos.name = "rotation rate" 
      coef_gp.axis(0).pos.long_name = "Normalized rotation rate" 
      coef_gp.name = "regression"
      coef_gp.long_name = "regression coefficient"
      return coef_gp      
    end

    private
    def get_data
      return [] if name.nil?  
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

  def gpaopen(varname,list="./")
    return GPhysArray.new(varname,list)        
  end
end


