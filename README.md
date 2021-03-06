# The Odin Project - Ruby on Rails
## Project: Associations - Private Events 

NOTE: This is in NO WAY a comprehensive walkthrough of the steps I used in the build, its just a rough set of notes for myself on the latest Odin Project app, Private Events. I've  missed loads of bits out, most of it is html stuff, the main flow at the start is all in the correct order following the steps on the site so you could follow along, but at points things wouldn't work so you would need to dig into the code to find the missing things from these notes. Apart from that, it all works. 

### Our Objective:

We have to build a site similar to a Eventbrite which allows users to create events and then manage user signups. I must be honest, I decided to cheat a little with this project and completely miss out the first part which was to setup the sign-in mechanism. I started with a copy and paste from our build of the rails tutorial up-to chapter 10. The reason I did this was I wanted to create a proper full featured application that I could use in production, so i wanted to save some time.

### Features

- A user can register for an account
- A user can login and logout
- A user can change their details
- Bootstrap source in vendor/assets
- Font awesome CSS source
- Google Analytics Integration

## Basic Events

### Step 1 Build and migrate your Event model

- rails generate model Event location:string date:date
- bundle exec rake db:migrate

### Step 2 Associations between the User and Event

    Add the association between the event creator (a User) and the event. 
    Call this user the "creator".

### In app\models\event.rb
- belongs_to :creator, :class_name => "User"

### In app\models\user.rb
- has_many :events, :foreign_key => :creator_id

### Add the foreign key to the Events model
- rails generate migration add_creator_to_events creator_id:integer

### Also add the index to the migration
- add_index  :events, :creator_id
- bundle exec rake db:migrate

### Step 3 User's Show page to list all users events

		<% if @user.events.any? %>
			<h3>Submitted (<%= @user.events.count %>) events</h3>
			<ul class="media-list">
				<%= render @events %>
			</ul>
			<%= will_paginate @events %>
		<% else %>
			<h3>No Events Found</h3>
		<% end %>

### The above renders the event from app/views/events/_event.html.erb

	<li class="media">
		<div class="media-left">
			<a href="#"><%= gravatar_for user, size: 50 %></a>
		</div>
		<div class="media-body">
			<h4 class="media-heading">Media heading</h4>
		</div>
	</li>

### Step 4 Create the  Events Controller and routes

- rails generate controller Events

### Steps 5, 6, 7, and 8

- For steps 5 to 8
- rails generate migration add_desc_to_events description:text
- bundle exec rake db:migrate
- Do all the normal CRUD actions and views.

- rails generate migration add_title_to_events title:string
- bundle exec rake db:migrate

## Attendance Step 1

### In app\models\user.rb

    has_many :attended_events,  :through => :event_attendees
	has_many :event_attendees,  :foreign_key => :attendee_id

### In app\models\event.rb

    has_many :attendees, 		:through => :event_attendees
	has_many :event_attendees,  :foreign_key => :attended_event_id

## Step 2

    rails generate model EventAttendee attendee_id:integer attended_event_id:integer
    rails generate controller EventAttendees
    bundle exec rake db:migrate

### In app\models\event_attendee.rb

	belongs_to :attendee, 		:class_name => "User"
	belongs_to :attended_event, :class_name => "Event"

	validates :attendee_id, 		presence: true
	validates :attended_event_id, 	presence: true

### Step 3 The event's show page to display a list of attendees

    <% if @event.attendees.any? %>
        <% @event.attendees.each do |attendee| %>
            <span class="attendee">
                <%= attendee.username %>
            </span> <br/>
        <% end %>
    <% else %>
        No attendees
    <% end %><br/>

### Step 4 The user's show page to display a list of events he is attending

	<% if @user.attended_events.any? %>
		<h2>Upcoming Events</h2> 
		<ul class="media-list">
			<%= render @upcoming_events %>
		</ul>
	<% else %>
		<h2>No Upcoming Events</h2>
	<% end %>

### In app\controllers\users_controller.rb
- @upcoming_events = @user.upcoming_events

### Step 5 On the user's show page show the past events

	<% if @events.past.any? %>
		<ul class="media-list">
			<%= render @events.past %>
		</ul>
	<% end %>

### In app\models\user.rb

#### Methods used in the user model

	def upcoming_events
		self.attended_events.upcoming
	end

	def previous_events
		self.attended_events.past
	end	

### Step 6 app\views\events\index.html.erb

	<h2>Upcoming Events</h2>
	<% if @events.upcoming.any? %>
		<ul class="media-list">
			<%= render @events.upcoming %>
		</ul>
		<%= will_paginate @events.upcoming %>
	<% else %>
		<h3>Events (0)</h3>
		<%= link_to new_event_path, class: 'btn btn-success' do %>
			Add Event <i class="fa fa-plus-circle"></i>
		<% end %>
	<% end %>

	<h2>Past Events</h2>
	<% if @events.past.any? %>
		<ul class="media-list">
			<%= render @events.past %>
		</ul>
		<%= will_paginate @events.past %>
	<% end %>

### Step 7 Simple Scopes in app\models\event.rb

	scope :upcoming, -> { where("Date >= ?", Date.today).order('Date ASC') }
	scope :past, 	 -> { where("Date <  ?", Date.today).order('Date DESC') }

### Step 8 Navigation
- Bootstrap nav used

### Step 9 Extra Credit

### In app\models\user.rb

	def attending?(event)
		event.attendees.include?(self)
	end

	def attend!(event)
		self.event_attendees.create!(attended_event_id: event.id)
	end

	def cancel!(event)
		self.event_attendees.find_by(attended_event_id: event.id).destroy
	end

### In app\views\events\show.html.erb

	<%= render 'attend_cancel' %>

### attend form in app\views\events

	<% if logged_in? && current_user.attending?(@event) %> 
		<%= render 'cancel' %>
	<% else %>
		<%= render 'attend' %>
	<% end %>

### cancel form in app\views\events

	<%= form_for(current_user.event_attendees.find_by(attended_event_id: @event.id),
		html: { method: :delete }) do |f| %>
		<%= f.submit "Cancel", class: "btn btn-sm btn-default" %>
	<% end %>

### attend form in app\views\events

	<% if logged_in? %>
		<%= form_for(current_user.event_attendees.build(attended_event_id: @event.id)) do |f| %>
		<%= f.hidden_field :attended_event_id %>
			<%= f.submit "Attend", class: "btn btn-sm btn-primary" %>
		<% end %>
	<% end %>

### Step 10

- git push

### Testing in the console

### Users

	u = User.first (Grab the first user)
	u.events.count ( Return the number of events )
	u.events ( Grab that users events )

	u.attended_events (Grab all events that user is going to - USING the join )
	u.event_attendees ( Returns the event and user id's NOT using the join )

### Events

	e = Event.first (Grab the first event)
	e.attendees (Grab events attendees (returns user objects) - GOING THROUGH the join )
	e.event_attendees ( Returns the event and user id's NOT GOING through the join )
	e.attendees.find(2).username  (Return the username of the user going to that event) 
	e.creator ( The user object that created the event )
	e.creator.username ( Pull out the creator username from the user object )

	e = Event.last
	e.creator.username
	e.attendees.each { |a| puts a.username }

### Looking at the upcoming and past scopes

	e = Event.all (Grab all the events)
	e.upcoming ( list all upcoming events )
	e.past ( list all past events )

