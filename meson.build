project('ballistic-pendulum', 'vala', 'c')

dependencies = [
    dependency('gtk4'),
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gee-0.8'),  # Add GEE dependency for the ArrayList
    meson.get_compiler('c').find_library('m', required: true)  # Math library
]

sources = [
    'src/main.vala',
    'src/window.vala',
    'src/simulation_area.vala',
    'src/oscillation_graph.vala'
]

executable('ballistic-pendulum',
    sources,
    dependencies: dependencies,
    install: true
)
