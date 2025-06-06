"""
Concrete Candy Tracker

This file is part of Concrete Candy Tracker. Concrete Candy Tracker is licensed under the 
terms of GNU General Public License as published by the Free Software Foundation. For more 
information and the LICENSE file, see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.

Streamlit dashboard. Work in progress... 
"""

# streamlit run "D:\GitHub\ConcreteCandyTracker\streamlit\src\dashboard_main.py"

# Import modules
import streamlit as st
import time
import threading
from camera import Camera
from dashboard_functions import *

# Set page layout
st.set_page_config(layout="wide", page_icon='📉')
st.title("Dashboard with time series plots")

# Set expander
expander = st.sidebar.expander('Settings', expanded=True)

# Initiate the session state variables
if 'camera' not in st.session_state:
    st.session_state.camera = Camera('169.254.1.69')
    st.session_state.run = False
    st.session_state.event = threading.Event()
    st.session_state.theard = threading.Thread()

# Start button
def start_run():
    st.session_state.run = True
    st.session_state.event = threading.Event()
    st.session_state.thread = threading.Thread(target=st.session_state.camera.start_grabbing, args=(st.session_state.event,))
    st.session_state.thread.start()

start_button = st.sidebar.button(
    label='Start grabbing',
    type='primary',
    key='start',
    disabled=st.session_state.run,
    on_click=start_run,
)

# Stop button
def stop_run():
    st.session_state.run = False
    st.session_state.event.set()

stop_button = st.sidebar.button(
    label='Stop grabbing',
    type='primary',
    key='stop',
    disabled=not st.session_state.run,
    on_click=stop_run,
)

# Initiate figures
## RGB values
fig_red = initiate_time_series_plot("Red", None, 5)
fig_green = initiate_time_series_plot("Green", None, 5)
fig_blue = initiate_time_series_plot("Blue", None, 5)
## CIELAB values
fig_l_star= initiate_time_series_plot("L*", None, 5)
fig_a_star = initiate_time_series_plot("a*", None, 5)
fig_b_star = initiate_time_series_plot("b*", None, 5)

# Create plotly graphs
## RGB values
plotly_red = st.plotly_chart(fig_red, use_container_width=True)
plotly_green = st.plotly_chart(fig_green, use_container_width=True)
plotly_blue = st.plotly_chart(fig_blue, use_container_width=True)
## CIELAB values
plotly_l_star = st.plotly_chart(fig_l_star, use_container_width=True)
plotly_a_star = st.plotly_chart(fig_a_star, use_container_width=True)
plotly_b_star = st.plotly_chart(fig_b_star, use_container_width=True)

while True:

    # Timing
    now = datetime.now()

    # Update the figures
    ## RGB values
    fig_red.data[0].update(x=st.session_state.camera.stack_time[0::10], y=st.session_state.camera.stack_r[0::10])
    fig_green.data[0].update(x=st.session_state.camera.stack_time[0::10], y=st.session_state.camera.stack_g[0::10])
    fig_blue.data[0].update(x=st.session_state.camera.stack_time[0::10], y=st.session_state.camera.stack_b[0::10])
    ## CIELAB values
    fig_l_star.data[0].update(x=st.session_state.camera.stack_time[0::10], y=st.session_state.camera.stack_l_star[0::10])
    fig_a_star.data[0].update(x=st.session_state.camera.stack_time[0::10], y=st.session_state.camera.stack_a_star[0::10])
    fig_b_star.data[0].update(x=st.session_state.camera.stack_time[0::10], y=st.session_state.camera.stack_b_star[0::10])

    # RGB Values
    fig_red.update_xaxes(range=[now-timedelta(minutes=5), now])
    fig_green.update_xaxes(range=[now-timedelta(minutes=5), now])
    fig_blue.update_xaxes(range=[now-timedelta(minutes=5), now])
    #fig_red.update_yaxes(range=[0, 255])           # Use this to set the limits of the y-axis
    #fig_green.update_yaxes(range=[0, 255])         # Use this to set the limits of the y-axis
    #fig_blue.update_yaxes(range=[0, 255])          # Use this to set the limits of the y-axis
    ## CIELAB values
    fig_l_star.update_xaxes(range=[now-timedelta(minutes=5), now])
    fig_a_star.update_xaxes(range=[now-timedelta(minutes=5), now])
    fig_b_star.update_xaxes(range=[now-timedelta(minutes=5), now])
    #fig_l_star.update_yaxes(range=[0, 255])        # Use this to set the limits of the y-axis
    #fig_a_star.update_yaxes(range=[0, 255])        # Use this to set the limits of the y-axis
    #fig_b_star.update_yaxes(range=[0, 255])        # Use this to set the limits of the y-axis

    ## RGB values
    plotly_red.container().plotly_chart(fig_red, use_container_width=True)
    plotly_green.container().plotly_chart(fig_green, use_container_width=True)
    plotly_blue.container().plotly_chart(fig_blue, use_container_width=True)
    ## CIELAB values
    plotly_l_star.container().plotly_chart(fig_l_star, use_container_width=True)
    plotly_a_star.container().plotly_chart(fig_a_star, use_container_width=True)
    plotly_b_star.container().plotly_chart(fig_b_star, use_container_width=True)

    # Pause
    time.sleep(1)

    # Print (debug)
    #print(now)
