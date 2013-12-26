#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 定数管理モジュール
# 
require "numru/ggraph"
require 'numru/gphys'
include NumRu
include Math
include NMath

module ConstShk
  # 定数
  StB = UNumeric[5.67e-8, "W.m-2.K-4"]   # ステファン・ボルツマン定数
  SolarConst = UNumeric[1366.0, "W.m-2"] # 太陽定数
  Grav    = UNumeric[9.8, "m.s-2"]       # 重力加速度
  RPlanet = UNumeric[6371000.0, "m"]     # 惑星半径
  RefPrs  = UNumeric[100000, "Pa"]       # 基準気圧
  LatentHeat = UNumeric[2.5e+6,"J.kg-1"] # 凝結の潜熱
  WtWet   = UNumeric[1000, "kg.m-3"]     # 水の密度
  MolWtWet = UNumeric[18.01528e-3, "kg.mol-1"] # 水蒸気の平均分子量
  MolWtDry = UNumeric[28.964e-3,"kg.mol-1"]    # 乾燥大気の平均分子量
  GasRUniv = UNumeric[8.3144621,"J.K-1.mol-1"] # 気体定数
  CpDry = UNumeric[1004,"J.K-1.kg-1"]    # 乾燥空気の定圧比熱
  GasRDry = GasRUniv/MolWtDry            # 乾燥空気の気体定数
end
