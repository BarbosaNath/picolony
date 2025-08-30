pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- main --

-- 2155 total
-- 172

-- init --
function _init()
	poke(0x5f2d, 1) -- mouse
	generate_world()
	
	mouse_x=0
	mouse_y=0
	
	camera_spd=2
	
	camera_x=0
	camera_y=0
	
	camera_x_offset=peek2(0x5f28)
	camera_y_offset=peek2(0x5f2a)
	
	selected = nil
	
	cursor_sp = 15
	cursor_mode = 'select'
	
	cursor_actions = {
		select=select_entity,
		mine=select_mine,
		chop=empty_fn,
		crop=empty_fn,
		attack=empty_fn,
		build=empty_fn,
	}
	
	fudeu=0
	to_log=''
	
	for i=1, 10 do
		person:generate()
	end
end


-- update --
function _update()
	check_released()

	for entt in all(entities) do
		entt:update()
	end
	
	mine_spot_frame=(mine_spot_frame+1)%20
	
	cursor_actions[cursor_mode]()
	
	camera_x_offset=peek2(0x5f28)
	camera_y_offset=peek2(0x5f2a)
	
	mouse_x=stat(32) + camera_x_offset
	mouse_y=stat(33) + camera_y_offset
	
	update_menu()
	
	-- camera movement
	if(btn(⬅️))camera_x-=1*camera_spd
	if(btn(➡️))camera_x+=1*camera_spd
	if(btn(⬆️))camera_y-=1*camera_spd
	if(btn(⬇️))camera_y+=1*camera_spd
end


-- draw --
function _draw()
 cls()

	map(0,0,0,0,size-20,size-20)
	
	draw_on_top = {}
	for entt in all(entities) do
		if (fget(entt.sp,3)) then
			add(draw_on_top, entt)
		else
			entt:draw()
		end
	end
	
	for entt in all(draw_on_top) do
		entt:draw()
	end
	
	draw_selected_entity()
	
	if selected~=nil then
		selected:draw_info()
	end
	
	draw_menu()
	draw_cursor()
	
	print_list(entities)
	
	print(fudeu, 50,50, 8)
	print(to_log,50,57, 8)
	
	camera(camera_x, camera_y)
end



function print_list(list)
	local a = #list*-7
	for e in all(list) do
		print(dump(e), 0,a,7)
		a+=7
	end
	
	print(#list,0,0,10)
end







-->8
-- util --

function pop_left(t)
	local value = t[1]
	
	deli(t, 1)
	
	return value
end


function is_empty(t)
	return #t == 0
end

function is_tbl(t)
	return	type(t) == 'table'
end

function dump(o)
   if is_tbl(o) then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s..k..': ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function empty_fn()end
-->8
-- class --

global=_ENV

class=setmetatable({
	new=function(self,tbl)
		tbl=tbl or {}
		
		setmetatable(tbl, {
			__index=self
		})
		
		tbl:init()
		
		return tbl
	end,
	
	init=function()end
},{__index=_ENV})

entities = {}
entity_id=0
entity=class:new({
	id=entity_id,
	x=0,
	y=0,
	sp=0,
	draw=function()end,
	update=function()end,
	draw_info=function()end,
	init=function(self)
		self.id = entity_id
		entity_id += 1
		add(entities, self)
	end,
})
-->8
-- world --

-- 1009

-- code by jolly uid=26356 --
terrain = {}
size = 50

-- make random numbered list
function create_list()
	for y=0,size do
	 terrain[y] = {} 
	for x=0,size do
		terrain[y][x] = flr(rnd(16)) + .5
	 
	 if flr(rnd(200)) == 1 then
	 terrain[y][x] = 100
	 end
		
		end
	end
end


--noise using averages
function noise(terrain,times)
	times = times or 1
	
	for i=1,times do
	for y=1,size-1 do
	for x=1,size-1 do
		terrain[y][x] = 
		flr((terrain[y-1][x-1]
		+terrain[y-1][x]
		+terrain[y-1][x+1]
		+terrain[y][x-1]
		+terrain[y][x+1]
		+terrain[y+1][x-1]
		+terrain[y+1][x]
		+terrain[y+1][x+1]) / 8)
	end
	end
	end
end
-- end of code by jolly --

rock_sps={
	64,65,66,67,
	80,81,82,83,
	96,97,98,99,
	112,113,114,115
}

water_sps={
	68,69,70,71,
	84,85,86,87,
	100,101,102,103,
	116,117,118,119
}

function in_sps(x,y,sps)
	for v in all(sps) do
		if v == mget(x,y) then
		 return true
		end
	end
	return false
end

function update_world() 
 function get_mod(x,y,t)
 	local counter = 0
-- 	counter+=in_sps(x-1,y-1,t) and 0 or 1
		counter+=in_sps(x  ,y-1,t) and 0 or 2
--		counter+=in_sps(x+1,y-1,t) and 0 or 4
		counter+=in_sps(x-1,y  ,t) and 0 or 8
--		counter+=in_sps(x  ,y  ,t) and 0 or 16
		counter+=in_sps(x+1,y  ,t) and 0 or 32
--		counter+=in_sps(x-1,y+1,t) and 0 or 64
		counter+=in_sps(x  ,y+1,t) and 0 or 128
--		counter+=in_sps(x+1,y+1,t) and 0 or 256
		return counter
 end
 
 
 function set_dynamic(x,y,t) 	
 	local m=get_mod(x,y,t)
 	
 	if((m&2 ) != 0)mset(x,y,t[2])
 	if((m&8 ) != 0)mset(x,y,t[5])
 	if((m&10) ==10)mset(x,y,t[1])
 	if((m&32) != 0)mset(x,y,t[7])
 	if((m&34) ==34)mset(x,y,t[3])
 	if((m&128)!= 0)mset(x,y,t[10])
 	if((m&136)==136)mset(x,y,t[9])
		if((m&160)==160)mset(x,y,t[11])
		if((m&130)==130)mset(x,y,t[14])
		if((m&138)==138)mset(x,y,t[13])
		if((m&162)==162)mset(x,y,t[15])
		if((m&40)==40)mset(x,y,t[8])
		if((m&42)==42)mset(x,y,t[4])
		if((m&168)==168)mset(x,y,t[12])
		if((m&170)==170)mset(x,y,t[16])
 end
 
 
 -- set complex terrain
 for x=0, size-10 do
	 for y=0, size-10 do
	  -- set rocks
	 	if in_sps(x,y,rock_sps) then
	 		 set_dynamic(x,y, rock_sps)
	 	end
	 	-- set water
	 	if in_sps(x,y,water_sps) then
	 		 set_dynamic(x,y, water_sps)
	 	end	
	 end 
 end
end

function generate_world()
	create_list()
	noise(terrain, 3)

	local rocks = 81
	local water = 85
	local grass = 32  
	local map_noise = {
		water, water, water, water,
		grass, grass, rocks, rocks,
		rocks, rocks, rocks, rocks,
		rocks, rocks, rocks, rocks,
	}

 -- set basic terrain
 for x=0, size-10 do
	 for y=0, size-10 do
	 	mset(x,y,map_noise[terrain[y+10][x+10]])
	 end 
 end
 
 
 function put_on_grass(q, s)
		for i=1, q do
	 	local x = flr(rnd(size-20))
	 	local y = flr(rnd(size-20))
	 	if mget(x,y) == 32 then
	 		mset(x,y,s)
	 		if(s==33)tree:new({x=x*8,y=y*8,leaves={}})
	 	end
	 end
 end
 
 -- set small rocks
 put_on_grass(flr(size/2), 48)
 
 -- set big rocks
 put_on_grass(flr(size/4), 49)

 -- set trees
 put_on_grass(flr(size/2+size/4), 33)
 
 
 update_world()
end
-->8
-- interaction utils --

function is_hovering(e,r)
	local is_t = is_tbl(e)
	local x, y = is_t and e.x or e, is_t and e.y or r
	local w, h = is_t and e.w or 8, is_t and e.h or 8
	
	if (
		mouse_x <= x+w and
		mouse_x >= x   and
		mouse_y <= y+h and
		mouse_y >= y
	) then 
		return true
	end
end

is_mouse_pressed=false
is_mouse_released=false
function check_released()
	if (is_mouse_released) is_mouse_released=false

	if stat(34) == 1 then
		is_mouse_pressed=true
	else
		if is_mouse_pressed then
			is_mouse_released=true
			is_mouse_pressed=false
		end
	end
end

function draw_cursor()
	spr(cursor_sp, mouse_x, mouse_y)
end
-->8
-- menu --

function draw_info_menu(llines, rlines) 
	rectfill(0+camera_x_offset,86+camera_y_offset,127+camera_x_offset,127+camera_y_offset,0)
	rect(0+camera_x_offset,86+camera_y_offset,127+camera_x_offset,127+camera_y_offset,7)
	
	local x = 3 + camera_x_offset
	local y = 89 + camera_y_offset
	
	function println(t,c)
		print(t,x,y,c)
		y+=7
	end
	
	for l in all(llines) do
		println(l.t, l.c)
	end
	
	x=63+camera_x_offset
	y=89+camera_y_offset
	
	for l in all(rlines) do
		println(l.t, l.c)
	end
end


function update_menu()
	local menu_modes={
		'select',
		'mine',
		'chop',
		'crop',
		'attack',
		'build',
	}

	if stat(34) == 1 then
		for i=1, 6 do
			local x, y = 8*(i-1)+camera_x_offset, camera_y_offset
			if is_hovering(x, y) then
				cursor_sp=16-i
				cursor_mode=menu_modes[i]
			end
		end
	end
end



function draw_menu()
	for i=25, 31 do
		local x, y = 8*(i-25)+camera_x_offset, camera_y_offset
		local sp = is_hovering(x, y) and i+16 or i
		spr(sp,x,y)
	end
end
-->8
-- person --

-- 626
-- 513 + 76

-- create new person --
person=entity:new({
	name=name,
	sp=1,
	variant=1,
	
	target={
		timer=-1,
		x=x,
		y=y,
		block=nil,
	},
	action='idle',
	nacts={}, --next_actions
--	lacts={}, --last_actions
	
	inv={},
	
	humor={
		happiness=5,
		sadness=0,
		hatred=0,
		love=0,
		boredon=0,
	},
	
	----------- methods -----------
	
	----------- actions -----------
	
	-- idle action --
	idle=function(_ENV)
		if target.timer == -1 then
			target.timer = flr(rnd(40))
		end
		
		target.timer -= 1
	
		if target.timer == 0 then
			--	add(lacts, 'idle')
			target.timer, action = -1, 'random_action'
		end
	end,
	
	
	-- move action --
	move=function(_ENV)
		if target.x == x
		and target.y == y then
			get_next_or_idle(_ENV,'move')
			
			sp = variant
			return
		end
	
		sp = ((sp) % 2) + variant
	
		if target.x != x then
			x += target.x > x and 1 or -1
		end
		
		if target.y != y then
			y += target.y > y and 1 or -1
		end
	end,
	
	
	-- check for mine spots --
	check_mine=function(_ENV)
		if #mine_spots == 0 then
			action='idle'
			return
		end
		
		for spot in all(mine_spots) do
			local space_flag = spot:check_around()
			if not spot.has_miner
			and space_flag > 0 then
				spot.has_miner = true
				
				target.block=spot
				
				for pos in all({
					{1,0,-1}, {2,-1,0},
					{4,1, 0}, {8, 0,1}
				}) do
					global.fudeu=space_flag&pos[1]>0
					if space_flag&pos[1]>0 then
						target.x = (spot.x+pos[2])*8
						target.y = (spot.y+pos[3])*8
						break
					end
				end
				
				action = 'move'
				add(nacts, 'mine')
				return
			end
		end
		
		action='idle'
	end,
	
	-- mine target block --
	mine=function(_ENV)
		if (target.timer==-1) target.timer=30
		
		if target.timer!=0 then 
			target.timer-=1
			return
		end
		
		local spot = target.block
		
		if(spot~=nil)mset(spot.x, spot.y, 36)
		
		del(entities, spot)
		del(mine_spots, spot)
		
		target.block=nil
		target.timer=-1
		update_world()
		action='check_mine'
	end,
	
	
	-- select random action --
	random_action=function(_ENV)	
		action = rnd({
			'idle',
			'random_move',
			'check_mine',
		})
	end,
	
	-- select random place to move --
	random_move=function (_ENV)
		local dis_x = flr(rnd(127))-63
		local dis_y = flr(rnd(127))-63
		
		local pos_x,pos_y = x+dis_x,y+dis_y
		
		-- out of map bounds
		if pos_x<0 or pos_x>(size-20)*8
		or pos_y<0 or pos_y>(size-20)*8
		then return end
		
		target.x,target.y=pos_x,pos_y

		-- move only to grass  		
		if (mget((target.x+4)/8, (target.y+4)/8) == 32)
		then action = 'move' end
	end,
	
	
	-- act acording to action --
	act=function(_ENV)
		_ENV[action](_ENV)
	end,
	
	
	---------- overloads ----------
	
	-- update --
	update=function(self)
		self:act()
	end,
	
	-- draw --
	draw=function(_ENV)
		spr(sp,x,y)
	end,
	
	-- render person information --
	draw_info=function(_ENV)
		draw_info_menu({
			{t=name, c=7},
			{t=action, c=5},
			{t=id, c=5},
			{t='x:'..x..' y:'..y, c=5},
			{t='tx:'..target.x..' ty:'..target.y, c=5},
		},	{
			{t='happiness: '..humor.happiness, c=10},
	  {t='sadness: '  ..humor.sadness,   c=13},
		 {t='hatred: '   ..humor.hatred,    c=8},
		 {t='love: '     ..humor.love,      c=14},
		 {t='boredon: '  ..humor.boredon,   c=6},
		})
	end,
	
	------ helper functions -------
	
	-- get next action or idle --
	get_next_or_idle=function(_ENV, last)
		if #nacts == 0	then
			--	add(lacts, last)
			action = 'idle'
		else
			action =	pop_left(nacts)
		end
	end,
	
	-- generate person --
	generate=function(self)
	 local sp = rnd({1,3})
		return self:new({
			name=rnd(
				{
					'alex', 'breno', 'claudio',
					'doug', 'eliza', 'francis',
					'guilheme', 'hilda', 'igor',
					'juniper', 'kai', 'lucas',
					'matheus', 'natalia', 
					'olivia', 'penelope', 
					'quentin',	'roger', 'silvia',
					'tulio', 'ursola',
					'vitoria', 'willian',
					'xavier','yasmin','zuko' 
				}
			),
			x=flr(rnd(127)),
			y=flr(rnd(127)),
			sp=sp,
			variant=sp,
			target={x=0,y=0,timer=0},
			nacts={},
			inv={},
		})
	end,

})


-- 76

--function check_boredon(p)
--	if #p.lacts >= 5 then
--		local counter = 0
--		
--		for i=#p.lacts-5,#p.lacts do
--			if p.lacts[i] == 'idle'
--			or p.lacts[i] == 'move'
--			then
--				counter += 1
--			end
--		end
--		
--		if counter == 5 then
--			deli(p.lacts, 1)
--			p.humor.boredon+=p.humor.boredon == 10 and 0 or 1
--		end
--	end
--end
--
--
--function check_humor(p)
--	check_boredon(p)
--end


-- debuging functions --
function debug_person(p)
	print(p.name)
	print(p.action)
	print('x: '..p.x..' y: '..p.y)
	print(dump(p.target))
	print('next: '..dump(p.nacts))
	print(p.sp)
end



-->8
-- tree --

leaf=class:new({
	x=0,
	y=0,
	sp=51,
	fh=false,
	fv=false,
	
	draw=function(_ENV)
		spr(sp,x,y,1,1,fh,fv)
	end
})

tree=entity:new({
	sp=34,
	
	leaves={},
	
	_init=function(_ENV)
		add(leaves,leaf:new({x=x  ,y=y}))
		add(leaves,leaf:new({x=x+8,y=y  ,sp=50,fh=true}))
		add(leaves,leaf:new({x=x-8,y=y  ,sp=50}))
		add(leaves,leaf:new({x=x  ,y=y+8,sp=35,fv=true}))
		add(leaves,leaf:new({x=x  ,y=y-8,sp=35}))
		
		for i=0,flr(rnd(4))+1 do
			add(leaves, leaf:new(rnd({
				{x=x+8,y=y+8,sp=52,fv=true},
				{x=x-8,y=y+8,sp=52,fh=true,fv=true},
				{x=x+8,y=y-8,sp=52},
				{x=x-8,y=y-8,sp=52,fh=true}
			})))
		end
	end,
	
	init=function(self)
		self.id = entity_id
		entity_id += 1
		add(entities, self)
		
		self:_init()
	end,
	
	draw=function(_ENV)
		spr(sp,x,y)
		for l in all(leaves) do
			l:draw()
		end
	end,
	
	update=function()end,
	
	draw_info=function(_ENV)
		draw_info_menu({
			{t='tree', c=7},
			{t=id, c=5},
		})
	end,
})			
-->8
-- select mode --

function select_entity()
	if stat(34) == 1 then
		reset_selected=true
		for entt in all(entities) do 
			if is_hovering(entt) then
				selected=entt
				reset_selected=false
				break
			end
		end
		
		if reset_selected then
			selected=nil
		end
	end
end

sel_frm = 0
function draw_selected_entity()
	if selected ~= nil then
	 spr(flr(sel_frm/3)+54,selected.x,selected.y)
	end
	
	sel_frm=(sel_frm+1)%30
end
-->8
-- mine mode --

mine_spot_frame=0
mine_spot=entity:new({
	sp=53,
	has_miner=false,
	
	check_around=function(_ENV)
		local counter = 0
		
		function check(x,y)
			return fget(mget(x, y), 1)
		end
		
		if (check(x  ,y-1)) counter+=1
		if (check(x-1,y  )) counter+=2
		if (check(x+1,y  )) counter+=4
		if (check(x  ,y+1)) counter+=8
		
		return counter
	end,
	
	draw=function(_ENV)
		if(flr(mine_spot_frame/10)==0)spr(sp,x*8,y*8)
	end,
})

mine_spots={}

function select_mine() 
	if not is_mouse_released 
	then return end
	
	local x, y = flr(mouse_x/8), flr(mouse_y/8)
	
	if not in_sps(x, y, rock_sps) 
	then return end

	for spot in all(mine_spots) do
		if  spot.x==x 
		and spot.y==y then
			del(mine_spots, spot)
			del(entities, spot)
			return
		end
	end
	
	add(mine_spots, mine_spot:new({x=x,y=y}))
end
__gfx__
00000000004444000044440000555500005555001100001100000000000000000000000000000000110111001110000000110000001000000111777101000000
00000000004f5ff0004f5ff00054144000541440100c010100000000000000000000000000000000171771001771000001171000017100001177111017100000
00700700004fff00004fff00005444000054440000ccc01000000000000000000000000000000000017771001777100011771000177710001771100017710000
00077000000cc000000cc000000cc000000cc0000ccc010000000000000000000000000000000000177710000177711017717100177771001717100017771000
00077000000cc000000cc000000cc000000cc00000c0c01000000000000000000000000000000000177171000017777117101710117717107111710017777100
00700700000c1000000c1000000c1000000c100001010c0000000000000000000000000000000000111017100001771017100171011101717100171017711000
00000000000110000001010000011000000101001010100100000000000000000000000000000000000001710001717111000017001000177100017101171000
00000000000110000110001000011000011000101100001100000000000000000000000000000000000000110000101700000001000000011000001100000000
dddddddddd6666dddd6666dddddddddd666666663300003300000000000000000000000004444440044444400444444004444440044444400444444000000000
dddddddddd6666dddd6666dddddddddd666666663009030300000000000000000044445544999944449999444499954444995944449995444499594455444400
66666666dd6666dddd666666dd6666dd666666660099303000000000000000000049445549559594495559944999559449995594499955544995559455449400
66666666dd6666dddd666666dd6666dd666666660993930000000000000000000004944549599994499955944995555449959554495555944999555454494000
66666666dd6666dddd666666dd6666dd666666660930393000000000000000000000000049999594499595944959559449599954499559944995959400000000
66666666dd6666dddd666666dd6666dd666666660303039000000000000000000000000049595594495995944599999445999994495959944959999400000000
dddddddddd6666dddddddddddddddddd666666663030300300000000000000000000000044999944449999444499994444999944449999444499994400000000
dddddddddd6666dddddddddddddddddd666666663300003300000000000000000000000004444440044444400444444004444440044444400444444000000000
bbbbbb3bbb54bb3b0000000000333300b44443544400004400000000000000000000000004444440044444400444444004444440044444400444444000000000
bbbbbbbbb34444bb0004400003333330344b44444094040404000500000000000044445544999944449999444499974444997944449997444499794455444400
bbb3bbbbb449944b0049940033333333454443440499404040000460000000000049445549779794497779944999779449997794499977744997779455449400
bb3bbbbbb49ff94b049ff9403333b333444454440999940004949444000000000004944549799994499977944997777449979774497777944999777454494000
bbbbbbbb449ff94b049ff940333b3b334b4344450099494004444400000000000000000049999794499797944979779449799974499779944997979400000000
bbbbbbbb55499444004994003333b33345444b340404049044000400000000000000000049797794497997944799999447999994497979944979999400000000
bbbbbbbb3344445500044000333b3b334444544b4040400440004000000000000000000044999944449999444499994444999944449999444499994400000000
bbbbb3bbbb35533b0000000033b3b3b334444b444400004450005000000000000000000004444440044444400444444004444440044444400444444000000000
bbbbbb3bbbbbbb3b0033333333333333000000002200002277000077dd0000dd0d0000d000000000000000000000000076000067770000777700007777000077
bb67bbbbbbbbbbbb033333333333b333333330002002020270000007d760067dd770077d0770077007700770077007706dd00dd67d0000d77000000770000007
bbd6bbbbbb6677bb3333333b333b3b3333333300002eee200000000006000060070000700700007007000070070000700d0000d0000000000000000000000000
b3bbbbbbb66667bb3333b3b333b3b3b333b3333002ee020000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb3bb776bdd6666b333b3b3b3b3b3b333b3b333000e0e02000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbb6ddbddddddb3333b3b333b3b3b3b3b3b33002e20e000000000006000060070000700700007007000070070000700d0000d0000000000000000000000000
77bbbbbbbbbbbbbb0333333b333b3b333b3b33302020200270000007d760067dd770077d0770077007700770077007706dd00dd67d0000d77000000770000007
6dbbb3bbbbbbb3bb0033333333333333b3b333302200002277000077dd0000dd0d0000d000000000000000000000000076000067770000777700007777000077
bbbdddddddddddddddddbbbbbbddddbbbbbbbbbbbbfbbbfbbfbbbbbfbbffffbbdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
bdddddddddddddddddddddbbbddddddbbbfbbbbbbbbbbbbbbbbbbbbbfffffffbdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
bd6d6d6d6d6d6d6d6d6d6ddbbd6d6ddbfbbbfffbfffbbbbffffbffbbfffccffbdd6d6d6d6d6d6d6d6d6d6ddddd6d6ddddd66666666666666666666dddd6666dd
ddd6d6d6d6d6d6d6d6d6d6dbddd6d6ddbbbffffffffffffffffffffbbffcccfbddd6d6d6d6d6d6d6d6d6d6ddddd6d6dddd66666666666666666666dddd6666dd
dd6d66666666666666666ddddd6d6dddbbfff77777ffff77777ffffbbffcccfbdd6d66666666666666666ddddd6d6ddddd66666666666666666666dddd6666dd
ddd6666d6d666d6666d6d6ddddd6d6ddbfff77cccc7777cccc77ffbbfffcccfbddd66666666666666666d6ddddd6d6dddd66666666666666666666dddd6666dd
dd6d6666666d66666d666ddddd6d6dddbbff7cccccccccccccc7ffbbffccccfbdd6d66666666666666666ddddd6d6ddddd66666666666666666666dddd6666dd
ddd66d66666666d66666d6ddddd6d6ddbfff7cccccccccccccc7ffbbbfcccfffddd66666666666666666d6ddddd6d6dddd66666666666666666666dddd6666dd
dd6d66d666666666666d6ddddd6d6dddbbff7cccccccccccccc7ffbbbfcccfffdd6d66666666666666666ddddd6d6ddddd66666666666666666666dddd6666dd
ddd66666666666666666d6ddddd6d6ddbbff7cc77cccccc77cc7fbbfffcccfffddd66666666666666666d6ddddd6d6dddd66666666666666666666dddd6666dd
dd6d6d666666666666666ddddd6d6dddfbff7c7cc7cccc7cc7c7fbbbfffccffbdd6d66666666666666666ddddd6d6ddddd66666666666666666666dddd6666dd
ddd66666666666666d66d6ddddd6d6ddbbbf77cccccccccccc7ffbbbbffcccfbddd66666666666666666d6ddddd6d6dddd66666666666666666666dddd6666dd
dd6d666d6666666666666ddddd6d6dddbbbff7cccccccccccc7ffbbbbffcccfbdd6d66666666666666666ddddd6d6ddddd66666666666666666666dddd6666dd
ddd66d66666666666666d6ddddd6d6ddbbbff7ccccc77ccccc7fffbffffcccfbddd66666666666666666d6ddddd6d6dddd66666666666666666666dddd6666dd
dd6d66666666666666d66ddddd6d6dddfbbff7cccc7cc7cccc7fffbbffccccfbdd6d66666666666666666ddddd6d6ddddd66666666666666666666dddd6666dd
ddd6d666666666666666d6ddddd6d6ddbbfff7cccccccccccc77ffbbbfcccfffddd66666666666666666d6ddddd6d6dddd66666666666666666666dddd6666dd
dd6d6666d66666d666d66ddddd6d6dddbbff7cccccccccccccc7fbfbbfcccfffdd6d66666666666666666ddddd6d6ddddd66666666666666666666dddd6666dd
ddd666d6666d66666666d6ddddd6d6ddbfff7cccccccccccccc7ffbbffcccfffddd66666666666666666d6ddddd6d6dddd66666666666666666666dddd6666dd
dd6d666666d66d666d666ddddd6d6dddbfff77cccc77777ccc77fffbfffccffbdd6d66666666666666666ddddd6d6ddddd66666666666666666666dddd6666dd
ddd66666666666666666d6ddddd6d6ddbffff77777fffff7777fffbbbffcccfbddd66666666666666666d6ddddd6d6dddd66666666666666666666dddd6666dd
dd6d6d6d6d6d6d6d6d6d6ddddd6d6dddbbffffffffffffffffffffbbbffcccfbdd6d6d6d6d6d6d6d6d6d6ddddd6d6ddddd66666666666666666666dddd6666dd
bdd6d6d6d6d6d6d6d6d6d6dbbdd6d6dbbbbffffffbbbbfffffffbbbfbfffcffbddd6d6d6d6d6d6d6d6d6d6ddddd6d6dddd66666666666666666666dddd6666dd
bbdddddddddddddddddddddbbddddddbbfbbbbfbbbbbbbbbbbfbbfbbbbffffbbdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
bbbddddddddddddddddddbbbbbddddbbbbbbbbbbbfbbbfbbfbbbbbfbbbbffbbbdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
bbbddddddddddddddddddbbbbdddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
bddddddddddddddddddddddbdd6d6ddbbffbfffffffbfffffffbfffbbbffffbbdddddddddddddddddddddddddd6d6dddddddddddddddddddddddddddd666666d
dd6d6d6d6d6d6d6d6d6d6dddd6d6d6ddffffffcccffffccccfffffffbffccffbdd6d6d6d6d6d6d6d6d6d6dddd6d6d6dddd66666666666666666666ddd666666d
ddd6d6d6d6d6d6d6d6d6d6dddd666d6dffcccccccccccccccccccccfbfccccfbddd6d6d6d6d6d6d6d6d6d6dddd666d6ddd66666666666666666666ddd666666d
dd6d6d6d6d6d6d6d6d6d6dddd6d666ddfccccccccccccccccccccccfbfccccfbdd6d6d6d6d6d6d6d6d6d6dddd6d666dddd66666666666666666666ddd666666d
ddd6d6d6d6d6d6d6d6d6d6dddd6d6d6dffccccffffccccffffccccffbffccffbddd6d6d6d6d6d6d6d6d6d6dddd6d6d6ddd66666666666666666666ddd666666d
bddddddddddddddddddddddbbdd6d6ddbffffffffffffffffffffffbbbffffbbddddddddddddddddddddddddddd6d6ddddddddddddddddddddddddddd666666d
bbbddddddddddddddddddbbbbbdddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444444444444000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004454444444544444000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444544444445000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444444444444000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444444444444000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444444444444000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444544444445444000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444444444444000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444444444444000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004454444444544444000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444544444445000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444444444444000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444444444444000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444444444444000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444544444445444000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000005444444444444444000000000000000000000000
__label__
b444444bb444444ff444444fb444444bb444444bb4444444144bbbbbbbb3333b333333b33333b3333bbbbbbbbbbbbbbbbbbbbbbbbb333b3b3b3b3b3b33b3b3b3
449999444499994444999544449959444499954444995944554444bbbbbb33333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbb3333b3b333b3b3b33b3b33
495595944955599449995594499955944999555449955594554494bbbbbbb33333b333333b33333bbbbbbbbbbbbbbbbbbbbbbbbbbbb333333b333b3b33b33333
49599994499955944995555449959554495555944999555454494bb3bbbbbbb3bbbb3333bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbb33333333333333333333
4999959449959594495955944959995449955994499595941bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbb33333bbbbbbb3bbbbbbb3bb3333b3b33b3b3b3b3b333
4959559449599594459999944599999449595994495999941bbbbbbbbbbbbbbbbbbbbbbbbbbbb33333b333333b33333bbbbbbbbbbbb333b3b3333b3b333b3333
4499994444999944449999444499994444999944449999441bbbb3bbbbbbb3bbbbbbb3bbbbbb33333333333333333333bbbbb3bbbbb33b3b3b3333b333b33333
b444444bb444444bb444444bb444444bb444444bb444444bbbbb3bbbbbbb3bbbbbbb3bbbbbb3333b333333b33333b3333bbb3bbbbbb333b3b3333b3b3333333b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333b3b3333b3b333b3b333bbbbbbbbbb3333b333333b3333333b3
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33b3b3b3333b333b3b3b33bbbbbbbbbbb33333333333333333b3b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333b3b3333b3b333b3b333bbbbbbbbbbbb33333b333333b3333b3
bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbb3333b3b33b3b3b3b3b3333bbbbbb3bbbbbbb3bbbb3333bb13333b
3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbb333333333333333333333bbbbbbb3bbbbbbb3bbbbbbb3b113333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333b3333333333bbb67bbbbbbbbbbbbbb67bbbbb33333
bbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbb3333333b333b3b33b3333333bbd6bbbbbbb3bbbbbbd6bbbb333333
bbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbb3333b3b333b3b3b33b3b3333b3bbbbbbbb3bbbbbb3bbbbbb3333b3
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333b3b3b3b3b3b33b3b3b333bb3bb776bbbbbbbbbb3bb776333b3b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333b3b333b3b3b33b3b3333bbbbb6ddbbbbbbbbbbbbb6dd3333b3
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333b333b3b33b333333b77bbbbbbbbbbbbbb77bbbbbbb33333
bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbb33333333333333333333bb6dbbb3bbbbbbb3bb6dbbb3bbbb3333
3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3b33b3b3b3b3b3333bbbbbbb3bbbbbbb3bbbbbbb3bb3333b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333b3b333b3b333bbbbbbbbbbbbbbbbbbbbbbbbbb333b3
bbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbb3333b333b3b3b33bbbb3bbbbbbb3bbbbbbb3bbbbb33b3b
bbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbb333b3b333b3b333bbb3bbbbbbb3bbbbbbb3bbbbbb333b3
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333b33333b3333bbbbbbbbbbbbbbbbbbbbbbbbbb3333b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbb3333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333b33333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333
bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbb3333bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3
3bbbbbbb3bbbbbbb3bbbbbbb3bbb33333bbbbbbb3bbbbbbb3bbb33333bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb
bbbbbbbbbbbbbbbbbbbbb33333b333333b33333bbbbbbbbbbbb333333b33333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb3bbbbbbb3bbbbbb33333333333333333333bbbbb3bbbb33333333333333bbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bb
3bbb3bbbbbbb3bbbbbb3333b333333b33333b3333bbb3bbbbb3333b33333b3333bbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbb
3bbbbbbbbbbbbbbbbbb333b3b3333b3b333b3b333bbbbbbbbb333b3b333b3b333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
3bbbbbbbbbbbbbbbbbb33b3b3b3333b333b3b3b33bbbbbbbbb3333b333b3b3b33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
3bbbbbbbbbbb4444bbb333b3b3333b3b333b3b333bbbbbbbbb333b3b333b3b333bbbbbbbbbbbbbbbbbbbbbbbbbbb4444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
3bbbbbb3bbbb4f5ffbb3333b3b33b3b3b3b3b3333bbbbbb3bb33b3b3b3b3b3333bbbbbb3bbbbbbb3bbbbbbb3bbbb4f5ffbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3
4bbbbbbb3bbb4fff3bbb333333333333333333333bbb333333333333333333333bbbbbbb3bbbbbbb3bbbbbbb3bbb4fff3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb
3bbbbbbbbbbbbccbbbb33333333333b3333333333bb33333333333b3333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
33bbb3bbbbbbbccbbb3333333b333b3b33b33333333333333b333b3b33b3333333bbb3bbbbbbb3bbbbbbb3bbbbbbbccbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bb
33bb3bbbbbbb3c1bbb3333b3b333b3b3b33b3b33333333b3b333b3b3b33b3b3333bb3bbbbbbb3bbbbbbb3bbbbbbb3c1bbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbb
33bbbbbbbbbbb1b1bb333b3b3b3b3b3b33b3b3b333333b3b3b3b3b3b33b3b3b333bbbbbbbbbbbbbbbbbbbbbbbbbbb11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
33bbbbbbbbb11bbb1b3333b3b333b3b3b33b3b33333333b3b333b3b3b33b3b3333bbbbbbbbbbbbbbbbbbbbbbbbbbb11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
3bbbbbbbbbbbbbbbbbb333333b333b3b33b333333bb333333b333b3b33b333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbb3bbbbbbb3bbbb33333333333333333333bbbb33333333333333333333bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3
3bbbbbbb3bbbbbbb3bbbbbbb3b33b3b3b3b3b3333dd3333b3b33b3b3b3b3b3333bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb
3bbbbbbbbbbbbbbbbbbbbbbbbb333b3b333b3b333dd333b3b3333b3b333b3b333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
3bbbb3bbbbbbb3bbbbbbb3bbbb3333b333b3b3b33d633b3b3b3333b333b3b3b33bbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bb
3bbb3bbbbbbb3bbbbbbb3bbbbb333b3b333b3b3336d333b3b3333b3b333b3b331117771bbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbb
3bbbbbbbbbbbbbbbbbbbbbbbbb3333b33333b3333663333b333333b33333b331177111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbb333333333333336d6d333333333333333333317711bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbb333333b33333666666333336333333d3333317171bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbb3bbbbbbb3bbbbbbb3bbbb3333bbddd66d66666666d6663333ddbbbbb711171bb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3
3bbbbbbb3bbbbbbb3bbbbbbb3bbbbddddd666666666666666666666666ddddb71bb171bb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbddddddd666666666666666666666666ddddd71bbb171bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb3bbbbbbb3bbbbbbb3bbbbbd6d6d6d6666666666666666666666666d6d61dbbbb11bbbbbb3bbbbbbb3bbbbbbb3bbbbbb6677bbbbb3bbbbbbb3bbbbbbb3bb
bbbb3bbbbbbb3bbbbbbb3bbbbbddd6d6d6666666666666666666666666d6d6d6dbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbb66667bbbb3bbbbbbb3bbbbbbb3bbb
bbbbbbbbbbbbbbbbbbbbbbbbbbdd6d666666666666666666666666666666666dddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdd6666bbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbddd6666d66666666666666666666666666d6d6ddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbddddddbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbdd6d66666666666666666666666666666d666dddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbb3bbbbbbb3bbbbbbb3bbddd66d666666666666666666666666666666d6ddbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3
3bbbbbbb3bbbbbbb3bbbbbbb3bdd6d66d666666666666666666666666666666666ddddddddddddddddddddbbbbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbddd6666666666666666666666666666666666666ddddddddddddddddddddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb3bbbbbbb3bbbbbbb3bbbbdd6d6d66666666666666666666666666666666666d6d6d6d6d6d6d6d6d6d6ddbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bb
bbbb3bbbbbbb3bbbbbbb3bbbbbddd6666666666666666666666666666666666666d6d6d6d6d6d6d6d6d6d6d6dbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbb
bbbbbbbbbbbbbbbbbbbbbbbbbbdd6d666d66666666666666666666666666666666666666666666666666666dddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbddd66d66666666666666666666666666666666666d666d666d666d6666d6d6ddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbdd6d666666666666666666666666666666666666666d6666666d66666d666dddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbb3bbbbbbb3bbbbbbb3bbddd6d66666666666666666666666666666666666666666d6666666d66666d6ddbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3
3bbbbbbbbbbfbbbbbfbbbbbb3bdd6d666666666666666666666666666666666666666666666666666666666666ddddbbbbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb
bbbbfbbbbbbbbbbbbbbbbbbbbbddd666d666666666666666666666666666666666666666666666666666666666ddddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbfbbbfffbfffbffbbbbb3bbbbdd6d6666666666666666666666666666666666666666666666666666666666666d6d6ddbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bb
bbbbbffffffffffffbbb3bbbbbddd6666666666666666666666666666666666666666666666666666666666666d6d6d6dbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbb
bbbbfff777777ffffbbbbbbbbbdd6d6d6d6666666666666666666666666666666666666666666666666666666666666dddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbfff77cccc77ffbbbbbbbbbbbdd6d6d66666666666666666666666666666666666666666666666666666666666d6d6ddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbff7cccccc7ffbbbbbbbbbbbbdddddd666666666666666666666666666666666666666666666666666666666d666dddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbfff7cccccc7ffbbbbbbb3bbbbbddddd666666666666666666666666666666666666666666666666666666666666d6ddbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3
bbccccccccccc7ffbbbbbbbb3bbbbbbb3bdd6d6666666666666666666666666666666666666666666666666666666d6dddbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb
bb7cccccc77cc7fbbfbbbbbbbbbbbbbbbbddd666d66666666666666666666666666666666666666666666666666666d6ddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
fbc7cccc7cc7c7fbbbbbb3bbbbbbb3bbbbdd6d666666666666666666666666666666666666666666666666666666666dddbbb3bbbbbbb3bbbbbbb3bbbbbbb3bb
ffcccccccccc7ffbbbbb3bbbbbbb3bbbbbddd666666666666666666666666666666666666666666666666666666d66d6ddbb3bbbbbbb3bbbbbbb3bbbbbbb3bbb
77cccccccccc7ffbbbbbbbbbbbbbbbbbbbdd6d6d6d66666666666666666666666666666666666666666666666666666dddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccc77ccccc7fffbfbbbbbbbbbbbbbbbbbdd6d6d66666666666666666666666666666666666666666666666666666d6ddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
cccc7cc7cccc7fffbbbbbbbbbbbbbbbbbbbbdddddd66666666666666666666666666666666666666666666666666d66dddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
cccccccccccc77ffbbbbbbb3bbbbbbb3bbbbbddddd6666666666666666666666666666666666666666666666666666d6ddbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3
ccccccccccccc7ffbbbbbbbb3bbbbbbb3bbbbbbb3bdd6d6666666666666666666666666666666666666666666666d66dddbbbbbb3bbbbbbb3bbbbbbb3bbb3333
c77cccccc77cc7fbbfbbbbbbbbbbbbbbbbbbbbbbbbddd666d666666666666666666666666666666666666666666666d6ddbbbbbbbbbbbbbbbbbbb33333b33333
7cc7cccc7cc7c7fbbbbbb3bbbbbbb3bbbbbbb3bbbbdd6d666666666666666666666666666666666666666666666d666dddbbb3bbbbbbb3bbbbbb333333333333
cccccccccccc7ffbbbbb3bbbbbbb3bbbbbbb3bbbbbddd6666666666666666666666666666666666666666666666666d6ddbb3bbbbbbb3bbbbbb3333b333333b3
cccccccccccc7ffbbbbbbbbbbbbbbbbbbbbbbbbbbbdd6d6d6d66666666666666666666666666666666666666666d6d6dddbbbbbbbbbbbbbbbbb333b3b3333b3b
ccccc77ccccc7fffbfbbbbbbbbbbbbbbbbbbbbbbbbbdd6d6d66666666666666666666666666666666666666666d6d6d6dbbbbbbbbbbbbbbbbbb33b3b3b3333b3
cccc7cc7cccc7fffbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddddd6666666666666666666666666666666666666666dddddddbbbbbbbbbbbbbbbbbb333b3b3333b3b
cccccccccccc77ffbbbbbbb3bbbbbbb3bbbbbbb3bbbbbddddd6666666666666666666666666666666666666666dddddbbbbbbbb3bbbbbbb3bbb3333b3b33b3b3
ccccccccccccc7ffbbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bdd6d66d66666666666666666d66666d666d66dddbbbbbb3bbbbbbb3bbbbbbb3bbb333333333333
c77cccccc77cc7fbbfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbddd666666666666666666666666d66666666d6ddbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333
7cc7cccc7cc7c7fbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbdd6d6d66666666666666666666d66d666d666dddbbb3bbbbbbb3bbbbbbb3bbbb33333333333333
cccccccccccc7ffbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbddd666666666666666666666666666666666d6ddbb3bbbbbbb3bbbbbbb3bbbbb33333b333333b3
cccccccccccc7ffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdd6d666d66666666666666666d6d6d6d6d6d6dddbbbbbbbbbbbbbbbbbbbbbbbb3333b3b3333b3b
ccccc77ccccc7fffbfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbddd66d666666666666666666d6d6d6d6d6d6d6dbbbbbbbbbbbbbbbbbbbbbbbbb333b3b3b3333b3
cccc7cc7cccc7fffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdd6d66666666666666666666dddddddddddddddbbbbbbbbbbbbbbbbbbbbbbbbbb333b3b3333b3b
cccccccccccc77ffbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbddd6d6666666666666666666dddddddddddddbbbbbbbb3bbbbbbb3bbbbbbb3bbb3333b3b33b3b3
ccccccccccccc7ffbbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bdd6d66666666666666d66dddbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbb333333333333
c77cccccc77cc7fbbfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbddd666d6666666666666d6ddbbbbbbbbbbbbbbbbbb67bbbbbbbbbbbbbbbbbbbbb33333333333b3
7cc7cccc7cc7c7fbbbbbb3bbbbbbb3bbbbbbb3bbbbbb6677bbdd6d6666666666666d666dddbbb3bbbbbbb3bbbbbbd6bbbbbbb3bbbbbbb3bbbb3333333b333b3b
cccccccccccc7ffbbbbb3bbbbbbb3bbbbbbb3bbbbbb66667bbddd66666666666666666d6ddbb3bbbbbbb3bbbbbb3bbbbbbbb3bbbbbbb3bbbbb3333b3b333b3b3
cccccccccccc7ffbbbbbbbbbbbbbbbbbbbbbbbbbbbbdd6666bdd6d6d6d666666666d6d6dddbbbbbbbbbbbbbbbbbb3bb776bbbbbbbbbbbbbbbb333b3b3b3b3b3b
ccccc77ccccc7fffbfbbbbbbbbbbbbbbbbbbbbbbbbbddddddbbdd6d6d666666666d6d6d6dbbbbbbbbbbbbbbbbbbbbbb6ddbbbbbbbbbbbbbbbb3333b3b333b3b3
cccc7cc7cccc7fffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddddd66666666dddddddbbbbbbbbbbbbbbbbb77bbbbbbbbbbbbbbbbbbbbbbb333333b333b3b
cccccccccccc77ffbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbddddd66666666dddddbbbbbbbb3bbbbbbb3bb6dbbb3bbbbbbb3bbbbbbb3bbbb333333333333
ccccccccccccccccccbfbbbbbfbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bdd6d6dddbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3b33b3b3
c77cccccc77cccccc7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbddd6d6ddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333b3b
7cc7cccc7cc7cccc7cfffbffbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbdd6d6dddbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbb3333b3
ccccccccccccccccccfffffffbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbddd6d6ddbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbb333b3b
cccccccccccccccccc777ffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdd6d6dddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333b3
ccccc77cccccc77ccccc77ffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdd6d6dbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333
cccc7cc7cccc7cc7ccccc7ffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbddddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333
ccccccccccccccccccccc7ffbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbddddbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbb3333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0001010101000000000000000000000084848400000800000000000000000000028288080208000000000000000000000282080808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
