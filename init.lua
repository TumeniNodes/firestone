local makes_fire = true -- set to false if you want to light the fire yourself and extinguish it
local group

if makes_fire == true then
  group = {immortal, not_in_creative_inventory=1}
else
  group = {immortal, not_in_creative_inventory=1, dig_immediate=3}
end

local function start_smoke(pos, node, clicker, chimney)
	local this_spawner_meta = minetest.get_meta(pos)
	local id = this_spawner_meta:get_int("smoky")
	local s_handle = this_spawner_meta:get_int("sound")
	local above = minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z}).name

	if id ~= 0 then
		if s_handle then
			minetest.after(0, function(s_handle)
				minetest.sound_stop(s_handle)
			end, s_handle)
		end
		minetest.delete_particlespawner(id)
		this_spawner_meta:set_int("smoky", nil)
		this_spawner_meta:set_int("sound", nil)
		return
	end

	if above == "air" and (not id or id == 0) then
		id = minetest.add_particlespawner({
			amount = 4, time = 0, collisiondetection = true,
			minpos = {x=pos.x-0.25, y=pos.y+0.4, z=pos.z-0.25},
			maxpos = {x=pos.x+0.25, y=pos.y+5, z=pos.z+0.25},
			minvel = {x=-0.2, y=0.3, z=-0.2}, maxvel = {x=0.2, y=1, z=0.2},
			minacc = {x=0,y=0,z=0}, maxacc = {x=0,y=0.5,z=0},
			minexptime = 1, maxexptime = 3,
			minsize = 4, maxsize = 8,
			texture = "smoke_particle.png",
		})
		if chimney == 1 then
			s_handle = nil
			this_spawner_meta:set_int("smoky", id)
			this_spawner_meta:set_int("sound", nil)
		else
		s_handle = minetest.sound_play("fire_small", {
			pos = pos,
			max_hear_distance = 5,
			loop = true 
		})
		this_spawner_meta:set_int("smoky", id)
		this_spawner_meta:set_int("sound", s_handle)
		end
	return end
end

local function stop_smoke(pos)
	local this_spawner_meta = minetest.get_meta(pos)
	local id = this_spawner_meta:get_int("smoky")
	local s_handle = this_spawner_meta:get_int("sound")

	if id ~= 0 then
		minetest.delete_particlespawner(id)
	end

	if s_handle then
		minetest.after(0, function(s_handle)
			minetest.sound_stop(s_handle)
		end, s_handle)
	end

	this_spawner_meta:set_int("smoky", nil)
	this_spawner_meta:set_int("sound", nil)
end

minetest.register_alias("firestone", "firestone:firestone")

minetest.register_craft({
  output = '"firestone:firestone" 1',
  recipe = {
    {'default:cobble', 'default:torch', 'default:cobble'},
    {'default:cobble', 'default:coal_lump', 'default:cobble'},
    {'default:cobble', 'default:cobble', 'default:cobble'},
  }
})

minetest.register_node("firestone:firestone", {
  description = "Fire Stone",
  tile_images = {"firestone_firestone_top.png", "firestone_firestone.png",
		"firestone_firestone.png", "firestone_firestone.png",
		"firestone_firestone.png", "firestone_firestone.png"},
  groups = {cracky=3, stone=2},
  damage_per_second = 4,
  after_place_node = function(pos)
    local t = {x=pos.x, y=pos.y+1, z=pos.z}
    local n = minetest.env:get_node(t)
    if n.name == "air" and makes_fire == true then
      minetest.env:add_node(t, {name="firestone:flame"})
    end
  end,
  after_dig_node = function(pos)
    local t = {x=pos.x, y=pos.y+1, z=pos.z}
    local n = minetest.env:get_node(t)
    if n.name == "firestone:flame" or n.name == "firestone:flame_low" then
      minetest.env:remove_node(t)
    end
  end,
})

minetest.register_node("firestone:flame", {
  description = "Fire",
  drawtype = "plantlike",
  tiles = {{
    name="firestone_flame_animated.png",
    animation={type="vertical_frames", aspect_w=1, aspect_h=1, length=1},
  }},
  inventory_image = "firestone_flame_inv.png",
  light_source = 14,
  groups = group,
  drop = '',
  walkable = false,
  damage_per_second = 4,
  selection_box = {
    type = "fixed",
    fixed = {-0.15, -0.5, -0.15, 0.15, 0.3, 0.15},
  },
})

minetest.register_node("firestone:flame_low", {
  description = "Fire",
  drawtype = "plantlike",
  tiles = {{
    name="firestone_flame_animated.png",
    animation={type="vertical_frames", aspect_w=1, aspect_h=1, length=1},
  }},
  inventory_image = "firestone_flame_inv.png",
  light_source = 14,
  groups = group,
  drop = '',
  walkable = false,
  damage_per_second = 4,
  selection_box = {
    type = "fixed",
    fixed = {-0.5, -0.5, -0.5, 0.5, -0.2, 0.5},
  },
})

minetest.register_abm({
  nodenames = {"firestone:firestone"},
  interval = 2,
  chance = 5,
  action = function(pos)
    local t = {x=pos.x, y=pos.y+1, z=pos.z}
    local n = minetest.env:get_node(t)
    if n.name == "firestone:flame_low" then
      minetest.env:set_node(t, {name="firestone:flame"})
    elseif n.name == "firestone:flame" then
      minetest.env:set_node(t, {name="firestone:flame_low"})
    end
    if n.name == "firestone:flame" then
      minetest.env:set_node(t, {name="firestone:flame"})
    end
  end,
})

--aximx51v chimney code

minetest.register_abm(
  {nodenames = {"firestone:chimney"},
  neighbors = {"group:igniter"},
  interval = 5.0,
  chance = 1,
  action = function(pos, node, active_object_count, active_object_count_wider)
    p_bottom = {x=pos.x, y=pos.y-1, z=pos.z}
    n_bottom = minetest.env:get_node(p_bottom)
    local chimney_top = false
    local j = 1
    local node_param = minetest.registered_nodes[n_bottom.name]
    if node_param.groups.igniter then
      while chimney_top == false do
        upper_pos = {x=pos.x, y=pos.y+j, z=pos.z}
        upper_node = minetest.env:get_node(upper_pos)
        if  upper_node.name == "firestone:chimney" then
           j = j+1
        elseif upper_node.name == "air" then
          minetest.env:place_node(upper_pos,{name="firestone:smoke"})
          chimney_top = true
          elseif upper_node.name == "firestone:smoke" then
          local old = minetest.env:get_meta(upper_pos)
          old:set_int("age", 0)
          chimney_top = true
        elseif upper_node.name ~= "air" or upper_node.name ~= "firestone:chimney" or upper_node.name ~= "firestone:smoke" then
          chimney_top = true
        end
      end
    end
  end,
})

minetest.register_abm(
  {nodenames = {"firestone:smoke"},
  interval = 5.0,
  chance = 20,
  action = function(pos, node, active_object_count, active_object_count_wider)
    local old = minetest.env:get_meta(pos)
    if old:get_int("age") == 1 then
      minetest.env:remove_node(pos)
    else
      old:set_int("age", 1)
    end
  end
})

minetest.register_craft({
  output = '"firestone:chimney" 4',
  recipe = {
    {'', 'default:cobble', ''},
    {'default:cobble', '', 'default:cobble'},
    {'', 'default:cobble', ''},
  }
})

minetest.register_node("firestone:chimney", {
  description = "Chimney",
  drawtype = "nodebox",
  node_box = {type = "fixed",
    fixed = {
      {0.3125, -0.5, -0.5, 0.5, 0.5, 0.5},
      {-0.5, -0.5, 0.3125, 0.5, 0.5, 0.5},
      {-0.5, -0.5, -0.5, -0.3125, 0.5, 0.5},
      {-0.5, -0.5, -0.5, 0.5, 0.5, -0.3125},
    },
  },
  selection_box = {
    type = "regular",
  },
  tiles ={"default_cobble.png"},
  paramtype = 'light',
  sunlight_propagates = true,
  walkable = true,
  groups = {cracky=2},
})

minetest.register_node("firestone:smoke", {
    description = "smoke",
    drawtype = "plantlike", 
    tiles ={{
    name="firestone_smoke_animated.png", animation={type="vertical_frames", aspect_w=1, aspect_h=1, length=2.0},
    }},
    sunlight_propagates = true,
    groups = groups,
    paramtype = "light",
    walkable = false,
    pointable = true,
    diggable = true,
    buildable_to = true,
    light_source = 10,
    on_place_node = function(pos)
        local old = minetest.env:get_meta(pos)
        old:set_int("age", 0)
    end
})
