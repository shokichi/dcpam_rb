#
#
#




def cp_ncf(file)
  ofile = NetCDF.open("rst.nc")
  GPhys::IO.var_names(file).each{ |varnames|
    gp = gpopen(file,varname)
    ofile.write(gp)
  }
  ofile.close  
end
 
  
