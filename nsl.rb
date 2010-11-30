require 'rubygems'
require 'vendor/sinatra/lib/dm-core'
require 'vendor/sinatra/lib/dm-migrations'
require 'vendor/sinatra/lib/sinatra.rb'

use Rack::MethodOverride

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/nsl.db")

class Project
  include DataMapper::Resource
  property  :id,              Serial
  property  :name,            String
  property  :priority,        Integer
  property  :created_on,      Date
  property  :completed_on,    Date

  has n, :tasks

  def self.active
    all(:completed_on => nil, :order => :priority)
  end

end

class Task
    include DataMapper::Resource
    property  :id,            Serial
    property  :name,          String
    property  :highlighted,   Boolean
    property  :project_id,    Integer
    property  :priority,      Integer
    property  :created_on,    Date
    property  :completed_on,  Date
    
    belongs_to :project

    def self.active
      all(:completed_on => nil, :order => :priority)
    end

    def self.now
      all(:completed_on => nil, :priority => 1)
    end
    
    def self.soon
      all(:completed_on => nil, :priority.gt => 1, :priority.lt => 7, :order => :priority)
    end
    
    def self.later
      all(:completed_on => nil, :priority.gt => 6, :order => :priority)
    end

end

DataMapper.finalize

# automatically create the entry table
DataMapper.auto_upgrade!


get '/' do
  @projects = Project.active
  erb :index
end

get '/now' do
  @projects = Project.active
  erb :now
end

get '/projects' do
  @projects = Project.active
  erb :projects
end

post '/project' do
  Project.create(:name => params[:name])
  redirect '/'
end

delete '/project' do
  project = Project.get(params[:id])
  active_projects = Project.active  
  project.update(:completed_on => Date.today)
  active_projects.each {|project| project.update(:priority => active_projects.index(project) + 1)}
  redirect '/'
end

get '/tasks' do
  @tasks = Task.active
  erb :tasks
end

post '/task' do
  active_tasks = Project.get(params[:project_id]).tasks.active
  default_priority = active_tasks.size + 1
  Task.create(:name => params[:name], :project_id => params[:project_id], :priority => default_priority, :created_on => Date.today)
  active_tasks.each {|task| task.update(:priority => active_tasks.index(task) + 1)}
  redirect '/'
end

put '/task' do
  task = Task.get(params[:id])
  task.update(:priority => params[:priority])
  redirect '/'
end

put '/rename' do
  task = Task.get(params[:id])
  task.update(:name => params[:name])
  redirect '/'
end

delete '/task' do
  task = Task.get(params[:id])
  project_id = task.project_id
  active_tasks = Project.get(project_id).tasks.active  
  task.update(:completed_on => Date.today)
  active_tasks.each {|task| task.update(:priority => active_tasks.index(task) + 1)}
  redirect '/'
end

put '/inc' do
  task = Task.get(params[:id])
  project_id = task.project_id
  new_priority = task.priority - 1
  ousted_task_priority = task.priority
  ousted_task = Task.first(:project_id => project_id, :priority => new_priority)
  task.update(:priority => new_priority)
  ousted_task.update(:priority => ousted_task_priority)
  redirect '/'
end

put '/dec' do
  task = Task.get(params[:id])
  project_id = task.project_id
  new_priority = task.priority + 1
  ousted_task_priority = task.priority
  ousted_task = Task.first(:project_id => project_id, :priority => new_priority)
  task.update(:priority => new_priority)
  ousted_task.update(:priority => ousted_task_priority)
  redirect '/'
end

get '/:s' do
  redirect '/'
end

enable :inline_templates

__END__

@@ layout
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<title></title>
  	<style type="text/css" media="screen">
  		/* Eric Meyer's Reset (http://meyerweb.com/eric/tools/css/reset/) */
  		/* v1.0 | 20080212 */

  		/* minified by Charlie Park (http://charliepark.org) */

  		a, abbr, acronym, address, applet, b, big, blockquote, body, caption, center, cite, code, dd, del, dfn, div, dl, dt, em, fieldset, form, font, h1, h2, h3, h4, h5, h6, html, i, iframe, img, ins, kbd, label, legend, li, object, ol, p, pre, q, s, samp, small, span, strike, strong, sub, sup, table, tbody, td, tfoot, th, thead, tr, tt, u, ul, var{background:transparent;border:0;font-size:100%;font-weight:normal;margin:0;outline:0;padding:0;vertical-align:baseline;}
  		body{font-family:"Gill Sans",'Helvetica Neue',helvetica,verdana,sans-serif;font-size:12px;line-height:18px;line-height:1}
  		ol, ul{list-style:none}
  		blockquote, q {quotes:none}
  		blockquote:before, blockquote:after, q:before, q:after{content: '';content: none}

  		/* remember to define focus styles! */
  		:focus{outline:0}

  		/* remember to highlight inserts somehow! */
  		ins{text-decoration:none}
  		del{text-decoration:line-through}

  		/* tables still need 'cellspacing="0"' in the markup */
  		table{border-collapse:collapse;border-spacing:0}

  a{color:#c00;text-decoration:none;}

  body{text-align:center;}
  
  button{background:none;border:0;color:#c00;display:inline;padding:0;}

  div#footer{clear:both;height:60px;margin-top:60px;padding-top:64px;}

  form{display:inline}

  h2{border-top:4px solid #c00;color:#333;font-size:48px;font-weight:lighter;line-height:90px;text-indent:2px;text-transform:uppercase;}
  h3{border-top:2px solid #333;font-size:32px;font-weight:lighter;line-height:60px;text-indent:2px;text-transform:uppercase;}
  .soon h3{border-color:#999}
  .later h3{border-color:#ccc}

  xinput{ background:rgba(0,255,255,0.2);border:0;font-size:12px;height:20px;line-height:20px;margin-right:-9px;position:absolute;top:1px;right:0;width:500px;-moz-border-radius:2px;}
  input.item{border:0;color:inherit;font-family:verdana;font-size:16px;height:auto;line-height:30px;}

  li{overflow:hidden;}
  li.do_list li{background:url('e.png') 0 0 repeat-x;font-family:verdana;font-size:16px;line-height:30px;margin:0;padding: 0 4px 0 34px;position:relative;text-indent:-30px}
  li.do_list li.sub{font-size:12px;padding-left:30px;}

  li.now{color:#333}
  li.soon{color:#999}
  li.later{color:#ccc}


  li.do_list{background:url('e.png') 0 100% repeat-x;float:left;margin-right:32px;width:384px} /* (3 * 300) + (2 * 30)  */
  li.do_list.later{margin-right:0;}
  li.project{clear:both;padding:96px 0 0;position:relative;}

  span{font:inherit}
  span.actions{display:none;position:absolute;top:0;right:0;}
  li li li:hover span.actions{display:block}

  li li li span.actions a{ border-left:1px solid #ccc;color:#c99;margin: 0;padding:0 8px;}
  li li li span.actions a:first-child{border:0}
  li li li:hover span.actions:hover a:hover{color:#c00}
  a.move:hover{cursor:move}

  td{font-family:verdana;font-size:14px;padding:4px 6px}
  
  textarea{border:0;border-left:1px solid #eee;color:inherit;display:block;font:inherit;height:90px;line-height:30px;opacity:.6;margin:0;padding:0 6px;width:100%;
  	DISPLAY:NONE;}

  ul#content{margin: 0 auto;text-align:left;width:1216px;}


  	</style>
</head>
<body>
<%= yield %>
</body>
</html>

@@ index
<ul id="content">
  <% for @project in @projects %>
	<li class="project">
		<h2><%= @project.name %></h2>
		<ul class="do_lists">
      <% ["now", "soon", "later"].each do |timeframe| %>
      <li class="do_list <%= timeframe %>">
        <%= erb :_tasks, :layout => nil, :locals => {:timespan => timeframe, :tasks =>@project.tasks.send(timeframe)} %>
      </li>
      <% end %>
		</ul>
	</li>
	<% end %>
</ul>
<form action="project" method="post">
  <input name="name" />
</form>

@@ now
<ul id="content" style="width:384px">
  <% for @project in @projects %>
	<li class="project">
		<h2><%= @project.name %></h2>
		<ul class="do_lists">
      <li class="do_list now">
        <%= erb :_tasks, :layout => nil, :locals => {:tasks =>@project.tasks.now} %>
      </li>
		</ul>
	</li>
	<% end %>
</ul>
<form action="project" method="post">
  <input name="name" />
</form>

@@projects
<table>
  <tr>
    <th>Task Name</th>
    <th>Project</th>
    <th>Priority</th>
    <th>Created On</th>
    <th>Completed On</th>
  </tr>
<% for @project in @projects %>
<tr>
  <td><%= @project.name %></td>
  <td><%= @project.priority %></td>
  <td><form method="post" action="project">
  <input type="hidden" name="_method" value="delete" />
  <input type="hidden" name="id" value="<%= @project.id %>" />
  <button>x</button>
</form></td>
</tr>
<% end %>
</table>

@@tasks
<table>
  <tr>
    <th>Task Name</th>
    <th>Project</th>
    <th>Priority</th>
    <th>Created On</th>
    <th>Completed On</th>
  </tr>
<% for @task in @tasks %>
<tr>
  <td><%= @task.name %></td>
  <td>Project: <%= Project.get(@task.project_id).name %></td>
  <td><form method="post" action="task">
    <input type="hidden" name="_method" value="put" />
    <input type="hidden" name="id" value="<%= @task.id %>" />
    <input name="priority" value="<%= @task.priority %>" />
  </form></td>
  <td><%= @task.created_on %></td>
  <td><%= @task.completed_on %></td>
</tr>
<% end %>
</table>

@@_tasks
<% if defined? timespan %>
<h3>do <%= timespan %></h3>
<% end %>
<ul>
  <% for task in tasks %>
  <li>
    <form method="post" action="rename">
      <input type="hidden" name="_method" value="put" />
      <input type="hidden" name="id" value="<%= task.id %>" />
      <input name="name" value="<%= task.name %>" style="border:0;color:inherit;font:inherit;width:320px" />
    </form>
    <form method="post" action="task" style="display:none">
      <input type="hidden" name="_method" value="put" />
      <input type="hidden" name="id" value="<%= task.id %>" />
      <input name="priority" />
    </form>
    <form method="post" action="inc">
      <input type="hidden" name="_method" value="put" />
      <input type="hidden" name="id" value="<%= task.id %>" />
      <button>^</button>
    </form>
    <form method="post" action="dec">
      <input type="hidden" name="_method" value="put" />
      <input type="hidden" name="id" value="<%= task.id %>" />
      <button>v</button>
    </form>
    <form method="post" action="task">
      <input type="hidden" name="_method" value="delete" />
      <input type="hidden" name="id" value="<%= task.id %>" />
      <button>x</button>
    </form>
  </li>
  <% end %>
  <% if defined? timespan == "later" %>
  <li>
    <form action="task" method="post">
      <input name="name" />
      <input type="hidden" name="project_id" value="<%= @project.id %>" />
      <input type="hidden" name="priority" value="20" />
    </form>
  </li>
	<% end %>
</ul>
  