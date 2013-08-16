#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 動画作成
# make animation
#

require 'numru/ggraph'
require 'numru/gphys'
include NumRu
include Math

def tunit2day(gp)
  time = gp.axis('time').pos
  if time.units.to_s == 'min' 
    time = time / (24 * 60) 
    time.units = Units["day"]
    gp.axis('time').set_pos(time)
  elsif time.units.to_s == 'hrs'
    time = time / 24
    time.units = Units["day"]
    gp.axis('time').set_pos(time)
  end
  return gp
end

def rain_lonlat(gp)
  min = nil
  max = nil
  int = 24 * 60 /40     # intv = 10 min
  int = 1 * 60/20 * 3   # 3 hours
  int = 1
  range_rain = {'min'=>min, 'max'=>max,'color_bar'=>true, 'levels'=>[rmiss,0,200,400,600,800,1000,1200,1400,1600,1800,2000,rmiss]}
  GGraph.tone_and_contour( gp[false,0]-1e-15, true, range_rain)
  GGraph.color_bar
  for i in 1..gp.axis('time').length-1
    GGraph.tone_and_contour( gp[false,i * int]-1e-15, true, 'keep'=>true)
  end
end

def lon_sig(gp,min,max,int,t)
  range = {'min'=>min, 'max'=>max}
  gp = gp.cut('lat'=>0)
  if gp.rank==3 
    GGraph.tone( gp[false,t * int], true, 'min'=>min, 'max'=>max,"annotate"=>false,"nlev"=>20)
    GGraph.color_bar
  elsif gp.rank==2 
    GGraph.line( gp[false,t * int], true, range)
  end
end



# file open
rain = GPhys::IO.open( dir +"local_" + data_name + ".nc",data_name)
#temp = GPhys::IO.open( dir +"local_" + "Temp" + ".nc","Temp")
#rh = GPhys::IO.open( dir + "local_" +"RH" + ".nc","RH")
#qvap = GPhys::IO.open( dir + "local_" + "QVap" + ".nc","QVap")
#p "ok"
# min to day
#=begin
rain = tunit2day(rain)
#temp = tunit2day(temp)
#rh = tunit2day(rh)
qvap = tunit2day(qvap)
time = rain.axis("time").to_gphys
deltime = time[1].val-time[0].val
#=end
# time range
st = 1440#*24*60
en = st + 5#*24*60
rain = rain.cut('time'=>st..en)
#temp = temp.cut('time'=>st..en)
#rh = rh.cut('time'=>st..en)
qvap = qvap.cut('time'=>st..en)

#int = 1 / deltime       # intv = 1 day
#int = 1 / deltime /24 * 3   # 3 hours
int = 1


# w.m-2 -> mm.h-1
#r = UNumeric[2265900, "1"] #"J.kg-1"
#rho = UNumeric[1000, "1"] #"kg.m-3"
#gp = gp[false,0]*(3600 ) * 1000 / r / rho 
#gp.units = "mm.hr-1"

# DCL
DCL::swlset('lwnd',false)
DCL.gropn(4)
DCL.sgpset('lcntl',false)
DCL.sgpset('lfull',true)
DCL.uzfact(0.7)
#DCL::gllset('LMISS', true)
#DCL::glrget('RMISS')
rmiss = DCL.glpget('rmiss')

DCL.sldiv('Y',1,2)
GGraph.set_fig "viewport"=>[0.15,0.85,0.05,0.25]
#GGraph.set_fig "viewport"=>[0.2,0.8,0.07,0.23]
# GGraph
#rain_lon_lat(gp)
for t in 0..rain.axis("time").length
  lon_sig(rain,0,4000,int,t)
#  lon_sig(temp,200,320,int,t)
#  lon_sig(temp.cut("sig"=>0.85..1),290,320,int,t)
#  lon_sig(rh,0,100,int,t)
  lon_sig(qvap,0,0.025,int,t)
#  break
end
DCL.grcls

# make movie
=begin
system("mkdir movie")
#print `date`
#if system("ls movie/")==false then
#  print `mkdir movie`
#end
#print `date`
dt = 100*dtime*int
system("mv dc_*.png movie")
system("cd movie/")

system("mogrify -format gif *.png")
system("convert -delay #{dt} dcl_*.gif output.gif")
system("rm dcl_*.gif")
=end
