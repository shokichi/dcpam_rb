#!/usr/bin/env ruby
#  
# 

require 'numru/ggraph'
require 'numru/gphys'
require 'narray'
require '/home/ishioka/ruby/lib/utiles_spe'
include Utiles_spe
include NumRu
include Math

def get_rain(dir)
  rain = GPhys::IO.open(dir + 'Rain.nc','Rain')
  rain = rain[false,0]
  grain = rain.copy
  grain[false] = Utiles_spe.glmean(grain).val

  r = UNumeric[2265900, "1"] #"J.kg-1"
  rho = UNumeric[1000, "1"] #"kg.m-3"

  grain = grain * (3600 * 24 * 360) * 1000 / r / rho + 1
  grain.units = 'mm.yr-1'
  grain.long_name = 'precipitation'
  return grain[0..1,0]
end
def get_hadley(dir)
  strm = GPhys::IO.open(dir.sub("local_","") + 'Strm.nc','Strm')
  strm = strm[false,0].mean("lon")
  hadley = strm.copy
  hadley[false] = (strm.max.val - strm.min.val)/2 
  hadley.long_name = 'Hadley circulation'
  return hadley[0..1,0]
end

dir, name = Utiles_spe.explist(ARGV[0])

# set DCL
if ARGV.index("-ps")
  DCL.gropn(2)
else
  DCL.gropn(1)
end
DCL.sgpset('lcntl',false)
DCL.uzfact(1.0)

# GGraph
#GGraph.set_fig('window'=>[65,85,150*(10**9),220*(10**9)])
GGraph.set_fig('window'=>[0,250*(10**9),0,1500])
GGraph.set_axes('xlabelint'=>5*10**10)

for n in 0..dir.length- 1
  hadley = get_hadley(dir[n])
  rain = get_rain(dir[n])
  if n == 0 then
    index = 14
    GGraph.scatter(  hadley, rain, true ,'index'=>14,'title'=>'','type'=>6, 'size'=>0.02 )  
  else
    index = index + 1
    GGraph.scatter( hadley, rain, false,'index'=>index,'type'=>6,'size'=>0.02 )  
  end
end

DCL.grcls

if ARGV.index("-ps") then
  print `mv dcl.ps hadley-rain.ps`
end



