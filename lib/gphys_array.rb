#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# GPhysArrayオブジェクト
# 
require "numru/ggraph"
require 'numru/gphys'
require "./utiles_spe.rb"
include Utiles_spe
include NumRu
include Math
include NMath

module AnalyDCPAM
  class GPhysArray
    def initialize(name,listfile)
      @@listfile = listfile
      @list = Explist.new(listfile)
      @name = name
      @data = get_data
      @legend = get_legend
    end

    def ref
      return self[@list.ref] 
    end

    def +(other_gpa)
      self.data.each_index do |n|
        gp1 = self.data[n]
        gp2 = search_gp(other_gpa,self.legend[n])
        gp = nil if gp1.nil? or gp2.nil?
        gp = gp1 + gp2 unless gp.nil?
        gp_ary << gp
      end
      result = self.clone
      result.data = gp_ary
      return result
    end

    def -(other_gpary)
      self.data.each_index do |n|
        gp1 = self.data[n]
        gp2 = search_gp(other_gpa,self.legend[n])
        gp = nil if gp1.nil? or gp2.nil?
        gp = gp1 - gp2 unless gp.nil?
        gp_ary << gp
      end
      result = self.clone
      result.data = gp_ary
      return result
    end

    def *(other_gpary)
      self.data.each_index do |n|
        gp1 = self.data[n]
        gp2 = search_gp(other_gpa,self.legend[n])
        gp = nil if gp1.nil? or gp2.nil?
        gp = gp1 * gp2 unless gp.nil?
        gp_ary << gp
      end
      result = self.clone
      result.data = gp_ary
      return result
    end

    def /(other_gpary)
      self.data.each_index do |n|
        gp1 = self.data[n]
        gp2 = search_gp(other_gpa,self.legend[n])
        gp = nil if gp1.nil? or gp2.nil?
        gp = gp1 / gp2 unless gp.nil?
        gp_ary << gp
      end
      result = self.clone
      result.data = gp_ary
      return result
    end

    def [](key)
      rerutn @data[@legend.index(key)]
    end

    private
    def get_data
      result = []
      @list.dir.each do |dir|
        result << gpopen dir + @name
      end
      return result
    end

    def get_legend
      @list.name
    end

    def search(legend)
      n = self.legend.index(legend)
      return nil if n.nil?
      return self.data[n]
    end
    public

    attr_reader :list,:name,:data,:legend
  end

  class GPhys
    def legend=(legend)
      @legend = leegnd
    end
    attr_reader :legend
  end
end
