pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- main --

-- init --
function _init()
	poke(0x5f2d, 1)
	generate_world()
	people = {}
	person_id = 1
	
	mouse_x=0
	mouse_y=0
	
	camera_x=0
	camera_y=0
	
	camera_x_offset=peek2(0x5f28)
	camera_y_offset=peek2(0x5f2a)
	
	selected = nil
	
	for i=0, 10 do
		add(people, generate_person())
	end
end


-- update --
function _update()
	for person in all(people) do
		act_person(person)
	end
	
	select_entity()
	
	camera_x_offset=peek2(0x5f28)
	camera_y_offset=peek2(0x5f2a)
		mouse_x=stat(32) + camera_x_offset
	mouse_y=stat(33) + camera_y_offset
	
	if(btn(⬅️))camera_x-=1
	if(btn(➡️))camera_x+=1
	if(btn(⬆️))camera_y-=1
	if(btn(⬇️))camera_y+=1
end


-- draw --
function _draw()
	
 cls()
 
--	debug_person(p)

	map(0,0,0,0,size-20,size-20)
	for p in all(people) do
		spr(p.sp, p.x, p.y)
	end
	
	
	draw_selection()
	
	if selected~=nil then
		person_info(selected)
	end
	draw_menu()
	
	draw_cursor()
	camera(camera_x, camera_y)
end








-->8
-- person --

-- create new person --
function new_person(
	name,x, y
)
	person_id += 1
	return {
		id=person_id,
		name=name,
		x=x,
		y=y,
		target={
			timer=-1,
			x=x,
			y=y,
			block=nil,
		},
		action='idle',
		nacts={}, --next_actions
		lacts={}, --last_actions
		sp=1,
		variant=1,
		inventory={},
		
		humor={
			happiness=5,
			sadness=0,
			hatred=0,
			love=0,
			boredon=0,
		},
		
		humor_text='neutral',
		humor_color=6,
		
		relations={}
	}
end


-- idle --
function idle(p)
	if p.target.timer == -1 then
		p.target.timer = flr(rnd(40))
	end
	
	p.target.timer -= 1

	if p.target.timer == 0 then
		add(p.lacts, 'idle')
		p.target.timer = -1
		p.action = 'random_action'
	end
end


-- move person --
function move_person(p)
	if p.target.x == p.x
	and p.target.y == p.y then
		if is_empty(p.nacts)	then
			add(p.lacts, 'move')
			p.action = 'idle'
		else
			p.action =	pop_left(p.nacts)
		end
		
		p.sp = p.variant
		return
	end

	p.sp = ((p.sp) % 2) + p.variant

	if p.target.x != p.x then
		p.x += p.target.x > p.x and 1 or -1
	end
	
	if p.target.y != p.y then
		p.y += p.target.y > p.y and 1 or -1
	end
end

-- select random action --
function select_random_action(p)	
	p.action = rnd({
		'idle',
		'move',
		'random_move',
	})
end


-- select random place to move --
function select_random_move(p)
	dis_x = flr(rnd(127))-63
	dis_y = flr(rnd(127))-63
	
	pos_x = p.x+dis_x
	pos_y = p.y+dis_y
	
	if pos_x<0 or pos_x>(size-20)*8
	or pos_y<0 or pos_y>(size-20)*8
	then return end
	
	p.target.x=pos_x
	p.target.y=pos_y
	
	if (mget((p.target.x+4)/8, (p.target.y+4)/8) == 32)
	then p.action = 'move' end
end


action = {
	idle=idle,
	move=move_person,
	random_action=select_random_action,
	random_move=select_random_move,
}	

-- act acording to action --
function act_person(p)
	action[p.action](p)
	check_humor(p)
end


function check_boredon(p)
	if #p.lacts >= 5 then
		local counter = 0
		
		for i=#p.lacts-5,#p.lacts do
			if p.lacts[i] == 'idle'
			or p.lacts[i] == 'move'
			then
				counter += 1
			end
		end
		
		if counter == 5 then
			deli(p.lacts, 1)
			p.humor.boredon+=p.humor.boredon == 10 and 0 or 1
		end
	end
end


function check_humor(p)
	check_boredon(p)
end



-- render person information --
function person_info(p)
	draw_info_menu({
		{t=p.name, c=7},
		{t=p.action, c=5},
	},	{
		{t='happiness: '..p.humor.happiness, c=10},
  {t='sadness: '  ..p.humor.sadness,   c=13},
	 {t='hatred: '   ..p.humor.hatred,    c=8},
	 {t='love: '     ..p.humor.love,      c=14},
	 {t='boredon: '  ..p.humor.boredon,   c=6},
	})
end


-- debuging functions --
function debug_person(p)
	print(p.name)
	print(p.action)
	print('x: '..p.x..' y: '..p.y)
	print(dump(p.target))
	print('next: '..dump(p.nacts))
	print(p.sp)
end


-- generate person --
function generate_person()
	local person = new_person(
		rnd(
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
		flr(rnd(127)),
		flr(rnd(127))
	)
	person.sp = rnd({1,3})
	person.variant = person.sp
	
	return person
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

function dump(o)
   if type(o) == 'table' then
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



-->8
-- world --

-- code by jolly uid=26356 --
terrain = {}
size = 100

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

function update_world()
	function in_t(x,y,t)
 	for v in all(t) do
 		if v == mget(x,y) then
 		 return true
 		end
 	end
 	return false
 end
 
 function get_mod(x,y,t)
 	local counter = 0
 	counter+=in_t(x-1,y-1,t) and 0 or 1
		counter+=in_t(x  ,y-1,t) and 0 or 2
		counter+=in_t(x+1,y-1,t) and 0 or 4
		counter+=in_t(x-1,y  ,t) and 0 or 8
		counter+=in_t(x  ,y  ,t) and 0 or 16
		counter+=in_t(x+1,y  ,t) and 0 or 32
		counter+=in_t(x-1,y+1,t) and 0 or 64
		counter+=in_t(x  ,y+1,t) and 0 or 128
		counter+=in_t(x+1,y+1,t) and 0 or 256
		return counter
 end

 
 
 function set_rock(x,y)
 	local rocks = {
 		64,65,66,67,
 		80,81,82,83,
 		96,97,98,99,
 		112,113,114,115
 	}
 	
 	local mod=get_mod(x,y,rocks)
 	
 	if((mod&2 ) != 0)mset(x,y,65)
 	if((mod&8 ) != 0)mset(x,y,80)
 	if((mod&10) ==10)mset(x,y,64)
 	if((mod&32) != 0)mset(x,y,82)
 	if((mod&34) ==34)mset(x,y,66)
 	if((mod&128)!= 0)mset(x,y,97)
 	if((mod&136)==136)mset(x,y,96)
		if((mod&160)==160)mset(x,y,98)
		if((mod&130)==130)mset(x,y,113)
		if((mod&138)==138)mset(x,y,112)
		if((mod&162)==162)mset(x,y,114)
		if((mod&40)==40)mset(x,y,83)
		if((mod&42)==42)mset(x,y,67)
		if((mod&168)==168)mset(x,y,99)
		if((mod&170)==170)mset(x,y,115)
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
	 	if mget(x,y)==81 then
	 		 set_dynamic(x,y, {
			 		64,65,66,67,
			 		80,81,82,83,
			 		96,97,98,99,
			 		112,113,114,115
			 	})
	 	end
	 	
	 	-- set water
	 	if mget(x,y)==85 then
	 		 set_dynamic(x,y, {
			 		68,69,70,71,
			 		84,85,86,87,
			 		100,101,102,103,
			 		116,117,118,119
			 	})
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
	 	end
	 end
 end
 
 -- set small rocks
 put_on_grass(40, 48)
 
 -- set big rocks
 put_on_grass(30, 49)

 -- set trees
 put_on_grass(60, 33)
 
 
 update_world()
end
-->8
-- interactions --

function select_entity()
	if stat(34) == 1 then
		reset_selected=true
		for p in all(people) do 
			if (
				mouse_x <= p.x+8 and
				mouse_x >= p.x and
				mouse_y <= p.y+8 and
				mouse_y >= p.y
			) then
				selected=p
				reset_selected=false
				break
			end
		end
		
		if reset_selected then
			selected=nil
		end
	end
end

selection_frame = 0
selection_frame_counter=0
function draw_selection()
	if selected ~= nil then
	 spr(selection_frame+54,selected.x,selected.y)
	end
	
	if selection_frame_counter == 0 then
		selection_frame=(selection_frame+1)%10
	end
	selection_frame_counter=(selection_frame_counter+1)%3
end


function draw_cursor()
	spr(15, mouse_x, mouse_y)
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

function draw_menu()
	spr(27,8*0+camera_x_offset,camera_y_offset)
	spr(28,8*1+camera_x_offset,camera_y_offset)
	spr(29,8*2+camera_x_offset,camera_y_offset)
	spr(30,8*3+camera_x_offset,camera_y_offset)
	spr(31,8*4+camera_x_offset,camera_y_offset)
end
__gfx__
00000000004444000044440000555500005555000000000000000000000000000000000000000000000000000000000077000077000000000000000001000000
00000000004f5ff0004f5ff000541440005414400000000000000000000000000000000000000000000000000000000070000007000000000000000017100000
00700700004fff00004fff0000544400005444000000000000000000000000000000000000000000000000000000000070000007000000000000000017710000
00077000000cc000000cc000000cc000000cc0000000000000000000000000000000000000000000000000000000000070000007000000000000000017771000
00077000000cc000000cc000000cc000000cc0000000000000000000000000000000000000000000000000000000000070000007000000000000000017777100
00700700000c1000000c1000000c1000000c10000000000000000000000000000000000000000000000000000000000070000007000000000000000017711000
00000000000110000001010000011000000101000000000000000000000000000000000000000000000000000000000070000007000000000000000001171000
00000000000110000110001000011000011000100000000000000000000000000000000000000000000000000000000077000077000000000000000000000000
dddddddddd6666dddd6666dddddddddd666666660000000000000000000000000000000000000000000000000444444004444440044444400444444004444440
dddddddddd6666dddd6666dddddddddd666666660000000000000000000000000000000000000000000000004499994444999944449999444499594444999544
66666666dd6666dddd666666dd6666dd666666660000000000000000000000000000000000000000000000004955959449555994495559944999559449995554
66666666dd6666dddd666666dd6666dd666666660000000000000000000000000000000000000000000000004959999449995594499955944995955449555594
66666666dd6666dddd666666dd6666dd666666660000000000000000000000000000000000000000000000004999959449959594499595944959995449955994
66666666dd6666dddd666666dd6666dd666666660000000000000000000000000000000000000000000000004959559449599594495995944599999449595994
dddddddddd6666dddddddddddddddddd666666660000000000000000000000000000000000000000000000004499994444999944449999444499994444999944
dddddddddd6666dddddddddddddddddd666666660000000000000000000000000000000000000000000000000444444004444440044444400444444004444440
bbbbbb3bbb54bb3b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbb34444bb0044440000333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb3bbbbb449944b04499440033b3b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb3bbbbbb49ff94b049ff94003b3b330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb449ff94b049ff940033b3b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb554994440449944003b3b330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb33444455004444003b3b3b33000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbb3bbbb35533b0000000033b3b3b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbb3bbbbbbb3b000000333b3b3b33000000000000000077000077dd0000dd0d0000d000000000000000000000000076000067770000777700007777000077
bb67bbbbbbbbbbbb003333b3b3b3b3b3333330000000000070000007d760067dd770077d0770077007700770077007706dd00dd67d0000d77000000770000007
bbd6bbbbbb6677bb033b3b3b3b3b3b3b3b3b3300000000000000000006000060070000700700007007000070070000700d0000d0000000000000000000000000
b3bbbbbbb66667bb03b3b3b3b3b3b3b3b3b3b3300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb3bb776bdd6666b033b3b3b3b3b3b3b3b3b3b300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbb6ddbddddddb03b3b3b3b3b3b3b3b3b3b330000000000000000006000060070000700700007007000070070000700d0000d0000000000000000000000000
77bbbbbbbbbbbbbb0033333b3b3b3b333b3b3b300000000070000007d760067dd770077d0770077007700770077007706dd00dd67d0000d77000000770000007
6dbbb3bbbbbbb3bb0000003333b3b33333b3b3300000000077000077dd0000dd0d0000d000000000000000000000000076000067770000777700007777000077
bbbdddddddddddddddddbbbbbbddddbbbbbbbbbbbbfbbbfbbfbbbbbfbbffffbbdddddddddddddddddddddddddddddddd00000000000000000000000000000000
bdddddddddddddddddddddbbbddddddbbbfbbbbbbbbbbbbbbbbbbbbbfffffffbdddddddddddddddddddddddddddddddd00000000000000000000000000000000
bd6d6d6d6d6d6d6d6d6d6ddbbd6d6ddbfbbbfffbfffbbbbffffbffbbfffccffbdd6d6d6d6d6d6d6d6d6d6ddddd6d6ddd00000000000000000000000000000000
ddd6d6d6d6d6d6d6d6d6d6dbddd6d6ddbbbffffffffffffffffffffbbffcccfbddd6d6d6d6d6d6d6d6d6d6ddddd6d6dd00000000000000000000000000000000
dd6d66666666666666666ddddd6d6dddbbfff77777ffff77777ffffbbffcccfbdd6d66666666666666666ddddd6d6ddd00000000000000000000000000000000
ddd6666d6d666d6666d6d6ddddd6d6ddbfff77cccc7777cccc77ffbbfffcccfbddd66666666666666666d6ddddd6d6dd00000000000000000000000000000000
dd6d6666666d66666d666ddddd6d6dddbbff7cccccccccccccc7ffbbffccccfbdd6d66666666666666666ddddd6d6ddd00000000000000000000000000000000
ddd66d66666666d66666d6ddddd6d6ddbfff7cccccccccccccc7ffbbbfcccfffddd66666666666666666d6ddddd6d6dd00000000000000000000000000000000
dd6d66d666666666666d6ddddd6d6dddbbff7cccccccccccccc7ffbbbfcccfffdd6d66666666666666666ddddd6d6ddd00000000000000000000000000000000
ddd66666666666666666d6ddddd6d6ddbbff7cc77cccccc77cc7fbbfffcccfffddd66666666666666666d6ddddd6d6dd00000000000000000000000000000000
dd6d6d666666666666666ddddd6d6dddfbff7c7cc7cccc7cc7c7fbbbfffccffbdd6d66666666666666666ddddd6d6ddd00000000000000000000000000000000
ddd66666666666666d66d6ddddd6d6ddbbbf77cccccccccccc7ffbbbbffcccfbddd66666666666666666d6ddddd6d6dd00000000000000000000000000000000
dd6d666d6666666666666ddddd6d6dddbbbff7cccccccccccc7ffbbbbffcccfbdd6d66666666666666666ddddd6d6ddd00000000000000000000000000000000
ddd66d66666666666666d6ddddd6d6ddbbbff7ccccc77ccccc7fffbffffcccfbddd66666666666666666d6ddddd6d6dd00000000000000000000000000000000
dd6d66666666666666d66ddddd6d6dddfbbff7cccc7cc7cccc7fffbbffccccfbdd6d66666666666666666ddddd6d6ddd00000000000000000000000000000000
ddd6d666666666666666d6ddddd6d6ddbbfff7cccccccccccc77ffbbbfcccfffddd66666666666666666d6ddddd6d6dd00000000000000000000000000000000
dd6d6666d66666d666d66ddddd6d6dddbbff7cccccccccccccc7fbfbbfcccfffdd6d66666666666666666ddddd6d6ddd00000000000000000000000000000000
ddd666d6666d66666666d6ddddd6d6ddbfff7cccccccccccccc7ffbbffcccfffddd66666666666666666d6ddddd6d6dd00000000000000000000000000000000
dd6d666666d66d666d666ddddd6d6dddbfff77cccc77777ccc77fffbfffccffbdd6d66666666666666666ddddd6d6ddd00000000000000000000000000000000
ddd66666666666666666d6ddddd6d6ddbffff77777fffff7777fffbbbffcccfbddd66666666666666666d6ddddd6d6dd00000000000000000000000000000000
dd6d6d6d6d6d6d6d6d6d6ddddd6d6dddbbffffffffffffffffffffbbbffcccfbdd6d6d6d6d6d6d6d6d6d6ddddd6d6ddd00000000000000000000000000000000
bdd6d6d6d6d6d6d6d6d6d6dbbdd6d6dbbbbffffffbbbbfffffffbbbfbfffcffbddd6d6d6d6d6d6d6d6d6d6ddddd6d6dd00000000000000000000000000000000
bbdddddddddddddddddddddbbddddddbbfbbbbfbbbbbbbbbbbfbbfbbbbffffbbdddddddddddddddddddddddddddddddd00000000000000000000000000000000
bbbddddddddddddddddddbbbbbddddbbbbbbbbbbbfbbbfbbfbbbbbfbbbbffbbbdddddddddddddddddddddddddddddddd00000000000000000000000000000000
bbbddddddddddddddddddbbbbdddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddddddddddddddddddddddddddddddd00000000000000000000000000000000
bddddddddddddddddddddddbdd6d6ddbbffbfffffffbfffffffbfffbbbffffbbdddddddddddddddddddddddddd6d6ddd00000000000000000000000000000000
dd6d6d6d6d6d6d6d6d6d6dddd6d6d6ddffffffcccffffccccfffffffbffccffbdd6d6d6d6d6d6d6d6d6d6dddd6d6d6dd00000000000000000000000000000000
ddd6d6d6d6d6d6d6d6d6d6dddd666d6dffcccccccccccccccccccccfbfccccfbddd6d6d6d6d6d6d6d6d6d6dddd666d6d00000000000000000000000000000000
dd6d6d6d6d6d6d6d6d6d6dddd6d666ddfccccccccccccccccccccccfbfccccfbdd6d6d6d6d6d6d6d6d6d6dddd6d666dd00000000000000000000000000000000
ddd6d6d6d6d6d6d6d6d6d6dddd6d6d6dffccccffffccccffffccccffbffccffbddd6d6d6d6d6d6d6d6d6d6dddd6d6d6d00000000000000000000000000000000
bddddddddddddddddddddddbbdd6d6ddbffffffffffffffffffffffbbbffffbbddddddddddddddddddddddddddd6d6dd00000000000000000000000000000000
bbbddddddddddddddddddbbbbbdddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddddddddddddddddddddddddddddddd00000000000000000000000000000000
__gff__
0001010101000000000000000000000084848400000000000000000000000000028288080000000000000000000000000282080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
