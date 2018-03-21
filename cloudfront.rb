require 'json'
require './git_module.rb'

# aws configure set preview.cloudfront true
# aws cloudfront list-invalidations --distribution-id EMA7SWJN66KTV

class Cloudfront
  include GitModule

  #
  # Purge the full cache in the App Central Pull Zone
  # (by sending no argument or a nil argument) or purge a single file or an Array of filenames
  # file_or_files - The uri to purge or the Array of uris to be purged.
  #
  def purge( distribution, file_or_files=nil )
    if file_or_files.nil?
      puts "Purging all files from [#{distribution}]"
      _purge( distribution )
    else
      file_or_files = file_or_files.is_a?(String) ? [ file_or_files ] : file_or_files
      puts "Purging specific files from [#{distribution}]"
      puts "Files are [#{file_or_files}]"
      _purge( distribution, file_or_files )
    end
  end

  #
  # Purge all the files that have been changed between
  # HEAD (The most recent commit in the index) and
  # the commit_sha argument (This can be a normal SHA or HEAD^, HEAD~2, etc)
  # commit_sha the commit_sha to diff with HEAD (This can be a normal SHA or HEAD^, HEAD~2, etc)
  #
  def purge_all_since_commit( distribution, commit_sha )
    _purge( distribution, git_files_changed( commit_sha ) )
  end

  #
  # Print information on all Distributions
  #
  def list_distributions
    distributions_json_string = `aws cloudfront list-distributions`
    distributions_json = JSON.parse( distributions_json_string )
    distributions_json['DistributionList']['Items'].each do | distribution |
      puts "Distribution Id [#{distribution['Id']}]"
      puts "Comment [#{distribution['Comment']}]"
      puts "DomainName [#{distribution['DomainName']}]"
      puts "Status [#{distribution['Status']}]"
      distribution['Origins']['Items'].each_with_index do | origin, index |
        puts "--> Origin [#{index+1}]"
        puts "    Origin Id [#{origin['Id']}]"
        puts "    Origin Id [#{origin['DomainName']}]"
        puts
        puts '    ------------------------------'
        puts
      end
      puts
      puts '----------------------------------'
      puts
    end
  end

  #
  # Print information on all Invalidations
  #
  def list_invalidations( distribution )
    invalidations_json_string = `aws cloudfront list-invalidations --distribution-id #{distribution} `
    invalidations_json = JSON.parse( invalidations_json_string )
    invalidations_json['InvalidationList']['Items'].each do | invalidation |
      puts "Invalidation Id [#{invalidation['Id']}]"
      puts "Invalidation Id [#{invalidation['Status']}]"
      puts "Invalidation Id [#{invalidation['CreateTime']}]"
      puts
      puts '--------------------------------'
      puts
    end
  end

  #
  # Get information on a specific invalidation
  #
  def get_invalidation( distribution, invalidation_id )
    puts `aws cloudfront get-invalidation --distribution-id #{distribution} --id #{invalidation_id} `
  end

  private

  def _purge( distribution, file_or_files=['/*'] )
    #puts "aws cloudfront create-invalidation --cli-input-json #{_build_invalidation( distribution, file_or_files )} "
    puts `aws cloudfront create-invalidation --cli-input-json '#{_build_invalidation(distribution, file_or_files)}' `
  end

  def _build_invalidation( distribution, file_or_files )
    JSON.dump( { "DistributionId" => distribution,
      "InvalidationBatch" => {
        "Paths" => {
          "Quantity" => file_or_files.size,
          "Items" => _start_with_slash( file_or_files )
        },
        "CallerReference" => "GLM_#{Time.now.strftime('%s')}"
      }
    } )
  end

  def _start_with_slash( file_or_files )
    file_or_files.collect do  | item |
      item =~ /^\// ? item : '/'+item
    end
  end

end

if __FILE__==$0
  if ARGV.size < 1 || ARGV[0] =~ /\-help/
      puts
      puts "usage: #{File.basename(__FILE__)} -option args"
      ins_meths = Cloudfront.instance_methods(false)
      puts "----------------"
      puts "Options are:"
      ins_meths.each do | method |
        puts "-#{method}"
      end
      puts "-help"
      puts "----------------"
      puts "The name of the option that you want to run is NOT optional...not specifying an option will cause this message to be rendered"
      puts
      exit
    elsif ARGV[0] =~ /^-/
      Cloudfront.new.send( ARGV[0].sub('-',''), *ARGV[1..-1] )
    else
      #problem with the argument
      raise "Arguments [#{ARGV}] are not the correct format"
    end
end
