{% macro render(posts) %}
{%- set current_year = '1970' %}
{%- for post in posts.toArray() %}

  {%- set year = date(post.date, 'YYYY') %}

  {%- if year !== current_year %}
    {%- set current_year = year %}
    <div class="collection-year">
      <span class="collection-header">{{ current_year }}</span>
      
      <div class="chinese-zodiac">
       {%- if current_year % 12 == 0 %}
         <i class="symbolic-animals icon-monkey"></i>
       {%- endif %}
       {%- if current_year % 12 == 1 %}
         <i class="symbolic-animals icon-rooster"></i>
       {%- endif %}
       {%- if current_year % 12 == 2 %}
         <i class="symbolic-animals icon-dog"></i>
       {%- endif %}
       {%- if current_year % 12 == 3 %}
         <i class="symbolic-animals icon-pig"></i>
       {%- endif %}
       {%- if current_year % 12 == 4 %}
         <i class="symbolic-animals icon-rat"></i>
       {%- endif %}
       {%- if current_year % 12 == 5 %}
         <i class="symbolic-animals icon-ox"></i>
       {%- endif %}
       {%- if current_year % 12 == 6 %}
         <i class="symbolic-animals icon-tiger"></i>
       {%- endif %}
       {%- if current_year % 12 == 7 %}
         <i class="symbolic-animals icon-rabbit"></i>
       {%- endif %}
       {%- if current_year % 12 == 8 %}
         <i class="symbolic-animals icon-dragon"></i>
       {%- endif %}
       {%- if current_year % 12 == 9 %}
         <i class="symbolic-animals icon-snake"></i>
       {%- endif %}
       {%- if current_year % 12 == 10 %}
         <i class="symbolic-animals icon-horse"></i>
       {%- endif %}
       {%- if current_year % 12 == 11 %}
         <i class="symbolic-animals icon-goat"></i>
       {%- endif %}
     </div>
    </div>
  {%- endif %}

  <article itemscope itemtype="http://schema.org/Article">
    <header class="post-header">

      <div class="post-meta">
        <time itemprop="dateCreated"
              datetime="{{ moment(post.date).format() }}"
              content="{{ date(post.date, config.date_format) }}">
          {{ date(post.date, 'MM-DD') }}
        </time>
      </div>

      <div class="post-title">
        {%- if post.link %}{# Link posts #}
          {%- set postTitleIcon = '<i class="fa fa-external-link-alt"></i>' %}
          {%- set postText = post.title or post.link %}
          {{ next_url(post.link, postText + postTitleIcon, {class: 'post-title-link post-title-link-external', itemprop: 'url'}) }}
        {% else %}
          <a class="post-title-link" href="{{ url_for(post.path) }}" itemprop="url">
            <span itemprop="name">{{ post.title or __('post.untitled') }}</span>
          </a>
        {%- endif %}
      </div>

    </header>
  </article>

{%- endfor %}
{% endmacro %}
