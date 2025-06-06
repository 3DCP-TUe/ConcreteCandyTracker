"""
Concrete Candy Tracker

This file is part of Concrete Candy Tracker. Concrete Candy Tracker is licensed under the 
terms of GNU General Public License as published by the Free Software Foundation. For more 
information and the LICENSE file, see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.

Methods for the streamlit dashboard. Work in progress... 
"""

import plotly.graph_objects as go
from datetime import datetime
from datetime import timedelta

def initiate_time_series_plot(name : str, title_yaxis : str, delta : float):
    
    fig = go.Figure()

    fig.add_scatter(
        name=name,
        mode='markers',
        marker_size = 3,
    )

    fig.update_layout(
        title=name,
        title_x=0.5,
        autosize=False,
        height=300,
        template='plotly_dark',
        margin=dict(
            l=25,
            r=25,
            b=0,
            t=25,
            pad=0,
        ),
        legend=dict(
            x=0,
            y=0,
        )
    )

    fig.update_xaxes(
        range=[datetime.now() - timedelta(minutes=delta), datetime.now()],
        tickformat='%H:%M:%S',
        mirror=True,
        ticks='inside',
        showline=True,
        tickwidth=3,
    )

    fig.update_yaxes(
        mirror=True,
        ticks='inside',
        showline=True,
        title=title_yaxis,
        tickwidth=3,
    )

    fig.update_layout(
        yaxis_tickformatstops = [
            dict(dtickrange=[None, -10], value=".0f"),
            dict(dtickrange=[-10, -1], value=".1f"),
            dict(dtickrange=[-1, 1], value=".2f"),
            dict(dtickrange=[1, 10], value=".1f"),
            dict(dtickrange=[10, None], value=".0f"),
        ]
    )

    return fig