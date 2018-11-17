--
-- Created by IntelliJ IDEA.  Copyright (C) 2017 Hanks
-- User: hanks
-- Date: 2017/5/26
-- A news app
--
require "import"
import "android.widget.*"
import "android.content.*"
import "android.view.View"
import "androlua.LuaHttp"
import "androlua.LuaAdapter"
import "androlua.widget.video.VideoPlayerActivity"
import "androlua.LuaImageLoader"
import "android.support.v7.widget.RecyclerView"
import "android.support.v4.widget.SwipeRefreshLayout"
import "androlua.adapter.LuaRecyclerAdapter"
import "androlua.adapter.LuaRecyclerHolder"
import "android.support.v7.widget.StaggeredGridLayoutManager"
import "androlua.widget.picture.PicturePreviewActivity"

local JSON = require("cjson")
local uihelper = require('uihelper')
local data = {}
local adapter
local imageWidth = uihelper.getScreenWidth()
local list = { index = 1, page = 1, urls = {} }
local maxHeight = uihelper.dp2px(640)

math.randomseed(os.time())
--- -然后不断产生随机数
list.page = math.floor(math.random() * 160)
-- create view table
local layout = {
    RelativeLayout,
    layout_width = "fill",
    layout_height = "fill",
    {
        RecyclerView,
        id = "recyclerView",
        layout_width = "fill",
        layout_height = "fill",
    },
    {
        TextView,
        id = "tv_loading",
        text = "加载中....",
        textSize = "12sp",
        textColor = "#888888",
        layout_margin = "16dp",
        layout_alignParentBottom = true,
        layout_alignParentRight = true,
    }
}

local item_view = {
    FrameLayout,
    layout_width = "fill",
    {
        ImageView,
        id = "iv_image",
        layout_width = "fill",
        layout_height = "200dp",
        scaleType = "fitXY",
    },
    {
        TextView,
        id = "tv_title",
        layout_gravity = "right",
        background = "#88000000",
        paddingLeft = "6dp",
        paddingRight = "6dp",
        paddingTop = "2dp",
        paddingBottom = "2dp",
        textSize = "10sp",
        visibility = 8,
        textColor = "#aaffffff",
    },
    {
        View,
        id = "layer",
        layout_width = "fill",
        layout_height = "fill",
        background = "@drawable/layout_selector_tran",
        clickable = true,
    },
}

local function fetchData()
    tv_loading.setVisibility(0)
    local url = string.format('http://pic.gamersky.com/home/getimagesindex?sort=hot_desc&pageIndex=%d&pageSize=50&nodeId=21086', list.page)

    LuaHttp.request({ url = url }, function(error, code, body)
        list.page = list.page + 1
        body = body:gsub('\\"', '"')
        body = body:sub(2, #body - 1)
        local arr = JSON.decode(body).body
        uihelper.runOnUiThread(activity, function()
            local s = #data
            for i = 1, #arr do
                local fullUrl = arr[i].originImg
                local w, h = arr[i].width, arr[i].height
                local item = { url = fullUrl, w = w, h = h }
                item.calcHeight = math.floor(imageWidth * tonumber(item.h) / tonumber(item.w))
                if item.calcHeight > maxHeight then item.calcHeight = maxHeight end
                data[#data + 1] = item
            end
            tv_loading.setVisibility(8)
            adapter.notifyItemRangeChanged(s, #data)
        end)
    end)
end

local function launchDetail(item)
    local args = { uris = { item.url }, headers = { 'Referer:http://gamersky.com', 'User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.109 Safari/537.36' } }
    PicturePreviewActivity.start(activity, JSON.encode(args))
end

function onCreate(savedInstanceState)
    activity.setStatusBarColor(0x33000000)
    activity.setContentView(loadlayout(layout))
    adapter = LuaRecyclerAdapter(luajava.createProxy('androlua.adapter.LuaRecyclerAdapter$AdapterCreator', {
        getItemCount = function()
            return #data
        end,
        getItemViewType = function(position)
            return 0
        end,
        onCreateViewHolder = function(parent, viewType)
            local views = {}
            local holder = LuaRecyclerHolder(loadlayout(item_view, views, RecyclerView))
            holder.itemView.getLayoutParams().width = imageWidth
            holder.itemView.setTag(views)
            views.layer.onClick = function(view)
                local position = holder.getAdapterPosition() + 1
                launchDetail(data[position])
            end
            return holder
        end,
        onBindViewHolder = function(holder, position)
            position = position + 1
            local item = data[position]
            local views = holder.itemView.getTag()
            views.iv_image.getLayoutParams().height = item.calcHeight
            LuaImageLoader.load(views.iv_image, item.url)
            if position == #data then fetchData() end
        end,
    }))
    recyclerView.setLayoutManager(StaggeredGridLayoutManager(1, StaggeredGridLayoutManager.VERTICAL))
    recyclerView.setAdapter(adapter)
    fetchData()
end
