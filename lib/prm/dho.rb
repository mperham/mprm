require 'aws/s3'

module DHO
  def self.sync_to_dho(path, accesskey, secretkey,pcomponent,prelease,object_store)
        component = pcomponent.join
        release = prelease.join
        puts object_store.inspect
        AWS::S3::Base.establish_connection!(
            :server             => object_store,
            :use_ssl            => true,
            :access_key_id      => accesskey,
            :secret_access_key  => secretkey
        )

        AWS::S3::Service.buckets.each do |bucket|
            unless bucket == path
                AWS::S3::Bucket.create(path)
            end
        end

        new_content = Array.new
        Find.find(path + "/") do |object|
            object.slice!(path + "/")
            if (object =~ /deb$/) || (object =~ /Release$/) || (object =~ /Packages.gz$/) || (object =~ /Packages$/) || (object =~ /gpg$/)
                f = path + "/" + object
                new_content << object
                AWS::S3::S3Object.store(
                    object,
                    open(f),
                    path
                )

                policy = AWS::S3::S3Object.acl(object, path)
                policy.grants = [ AWS::S3::ACL::Grant.grant(:public_read) ]
                AWS::S3::S3Object.acl(object,path,policy)
            end
        end

        bucket_info = AWS::S3::Bucket.find(path)
        bucket_info.each do |obj|
            o = obj.key
            if (o =~ /deb$/) || (o =~ /Release$/) || (o =~ /Packages.gz$/) || (o =~ /Packages$/) || (o =~ /gpg$/)
                unless new_content.include?(o)
                    AWS::S3::S3Object.delete(o,path)
                end
            end
        end
        puts "Your apt repository is located at http://#{object_store}/#{path}/"
        puts "Add the following to your apt sources.list"
        puts "deb http://#{object_store}/#{path}/ #{release} #{component}"
    end
end


