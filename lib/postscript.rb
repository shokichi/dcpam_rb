#!/usr/bin/env ruby
#
#
#
#

module PostScript
  def convert_ps2eps(psfile,prefix="./")
    ps_pages = get_Pages(psfile)
    if ps_pages == 1
      outfile = prefix+"/"+psfile  
      system "pstoeps.rb #{outfile}"
      system "rm -f #{outfile}"
    else
      ps_pages.times do |n|
        outfile = prefix+"/"+psfile.sub(".ps","_#{'%03d'%(n+1)}.ps")
        system "psselect #{n+1} #{psfile} #{outfile}"
        system "pstoeps.rb #{outfile}"
        system "rm -f #{outfile}"
      end
    end
  end

  def get_Pages(file_path)
    File.open(file_path) do |file|
      file.seek(-30, IO::SEEK_END)
      file.each_line do |line| 
        return parse_pages(line) if line.include?("Pages")
      end
    end
  end
  
  def parse_pages(str)
    return str.split(":")[-1].to_i
  end
end
