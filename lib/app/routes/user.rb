module ExercismWeb
  module Routes
    class User < Core
      # Become nitpicker. How did I decide on this particular route?
      post '/exercises/:language/:slug' do |language, slug|
        please_login

        exercise = current_user.exercises.where(language: language, slug: slug).first
        exercise.unlock! if exercise
        redirect back
      end

      get '/:username' do |username|
        please_login
        user = ::User.find_by_username(username)

        if user
          title(user.username)
          erb :"user/show", locals: { profile: Profile.new(user, current_user) }
        else
          status 404
          erb :"errors/not_found"
        end
      end

      get '/:username/:key' do |username, key|
        please_login
        user = ::User.find_by_username(username)
        exercise = user.exercises.find_by_key(key)
        if exercise.nil?
          # Should this be a 404?
          flash[:notice] = "Couldn't find that exercise."
          redirect '/'
        elsif exercise.submissions.empty?
          # We have orphan exercises at the moment.
          flash[:notice] = "That submission no longer exists."
          redirect '/'
        else
          redirect ["", "submissions", exercise.submissions.last.key].join('/')
        end
      end

      put '/me/uuid/reset' do
        please_login

        # This could fail, but I don't know
        # what the user should see in that case.
        # Do we even have a way of showing a message?
        current_user.reset_key
        current_user.save
        redirect "/account"
      end
    end
  end
end
