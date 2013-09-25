#!/usr/bin/env ruby
#

expdir = ARGV[0]
origdir = "/home/ishioka/dcpam/dcpam5-20120813-2"

if expdir == nil 
  expdir = `pwd`.chop
elsif expdir[-1..-1] == "/" 
  expdir = expdir.chop
  if system("ls #{expdir}")==false then
    system("mkdir #{expdir}")
  end
end

system("cp #{origdir}/chkgmake.cfg #{expdir}/")
system("cp #{origdir}/chkrps.cfg #{expdir}/")
system("cp #{origdir}/chkfort.cfg #{expdir}/")
system("cp #{origdir}/Config.mk #{expdir}/")
system("cp #{origdir}/rules.make #{expdir}/")
system("cp #{origdir}/install-sh #{expdir}/")
system("cp #{origdir}/Makefile #{expdir}/")
system("cp #{origdir}/Config.mk #{expdir}/")
system("cp -R #{origdir}/src #{expdir}/")

system("mkdir #{expdir}/exp ")
system("mkdir #{expdir}/exp/bin #{expdir}/exp/conf #{expdir}/exp/rst_data #{expdir}/exp/data")
system("cp /home/ishioka/dcpam/dcpam-exp/conf/*.conf #{expdir}/exp/conf/")


make_dcpam = File.open("#{expdir}/make_dcpam","w")
make_dcpam.print "make clean\n" 
make_dcpam.print "make clean.all\n" 
make_dcpam.print "export FC=mpif90\n"
make_dcpam.print 'export FFLAGS="-fastsse -Minfo=all"'
make_dcpam.print "\n./configure --with-ispack=/home/ishioka/dcpam/mpilib/ispack/libisp.a --with-netcdf=/home/ishioka/dcpam/mpilib/netcdf/lib/libnetcdf.a --with-gtool5=/home/ishioka/dcpam/mpilib/gtool/lib/libgtool5.a --with-spml=/home/ishioka/dcpam/mpilib/spml/lib/libspml-vec.a --prefix=#{expdir}/ --enable-mpi\n"
make_dcpam.print "make" 
make_dcpam.close
