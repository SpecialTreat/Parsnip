
min_font = 7
font_step = 0.5

min_width = 240.0
max_width = 2560.0
width_step = 18.0

width = 0
font = 0

count = int((max_width - min_width) / width_step)

print('''html{{font-size:{}px}}'''.format(str(min_font + (count * font_step)).rstrip('0').rstrip('.')))

template = '''@media all and (max-width:{0}px), all and (max-height:{0}px){{html{{font-size:{1}px}}}}'''

for i in xrange(count - 1, -1, -1):
    width = str(min_width + (i * width_step)).rstrip('0').rstrip('.')
    font = str(min_font + (i * font_step)).rstrip('0').rstrip('.')
    print(template.format(width, font))

