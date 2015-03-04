require_relative "helper"

test do
  class UserPhotos < Cuba
    define do
      on root do
        res.write "uid: %d" % vars[:user_id]
        res.write "site: %s" % vars[:site]
      end
    end
  end

  class Photos < Cuba
    define do
      on ":id/photos" do |id|
        with user_id: id do
          _, _, body = UserPhotos.call(req.env)

          body.each do |line|
            res.write line
          end
        end

        res.write vars.inspect
      end
    end
  end

  Cuba.define do
    on "users" do
      with user_id: "default", site: "main" do
        run Photos
      end
    end
  end

  _, _, body = Cuba.call({ "PATH_INFO" => "/users/1001/photos",
                           "SCRIPT_NAME" => "" })

  assert_response body, ["uid: 1001", "site: main",
                         '{:user_id=>"default", :site=>"main"}']
end
