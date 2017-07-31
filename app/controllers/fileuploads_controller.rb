class FileuploadsController < ApplicationController

  def new
  end

  def index
    file = Dir.glob(Rails.root.join('tmp', '*.xlsx'))
    doc = Roo::Spreadsheet.open(file[0])
    movies = []
    doc.sheet("Sheet1").each(id: 'id', label: 'label', next_type: 'next_type', parent_id: 'parent_id', to_web: 'to_web') do |hash|   
      movies.push(hash)
    end
    File.delete(file[0])
   
    nested_hash = Hash[ movies.drop(1).map{|e| [e[:id], e.merge(children: [])]}]
    nested_hash.each do |id, item|
      parent = nested_hash[item[:parent_id]]
      parent[:children] << item if parent
    end
    
    @tree = JSON.pretty_generate(nested_hash.select { |id, item| item[:parent_id].nil? }.values)
    
    file_name = "converted_file.json"
    save_path = Rails.root.join('tmp')
    File.open(save_path+file_name, 'w'){|file|
      file.write(@tree)
    }
    
    render :json => @tree
  end

  def create 
    uploaded_file = fileupload_param[:file]
    temp_dir = Rails.root.join('tmp')
    Dir.mkdir(temp_dir) unless Dir.exists?(temp_dir)
	  output_path = Rails.root.join('tmp', uploaded_file.original_filename)
	
	  File.open(output_path, 'w+b') do |fp|
	    fp.write  uploaded_file.read
	  end
		  redirect_to action: 'index'
  end

  private
  def fileupload_param
    params.require(:fileupload).permit(:file)
  end
end
