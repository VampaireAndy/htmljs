Topic = __M 'topics'
TopicComment = __M 'topic_comments'
User = __M 'users'
User.hasOne Topic,{foreignKey:"user_id"}
Topic.belongsTo User,{foreignKey:"user_id"}

Tag = __M 'topic/tags'
Tag.hasOne Topic,{foreignKey:"tag_id"}
Topic.belongsTo Tag,{foreignKey:"tag_id"}
TopicZanLogs = __M 'topic_zan_logs'
User.hasOne TopicZanLogs,{foreignKey:"user_id"}
TopicZanLogs.belongsTo User,{foreignKey:"user_id"}
TopicZanLogs.sync()
Topic.sync()
TopicComment.sync()

func_topic =
  run_sort:()->
    self = this
    this.getAllByField 1,10000,null,(error,articles)->
      if articles && articles.length
        articles.forEach (a)->
          self.run_sort_byid a.id
  run_sort_byid:(articleId)->
    Topic.find
      where:
        id:articleId
    .success (article)->
      if article && article.last_comment_time
        score = (article.comment_count+article.visit_count/100)/Math.pow((new Date().getTime()-article.last_comment_time.getTime())/1000/60/60+2,1.5)
        article.updateAttributes({score:score},['score'])
        .success ()->
    .error (error)->
      callback error
  getAllByField:(page,count,condition,order,callback)->
    if not callback
      callback = order
      order = "sort desc,id desc"
    query =
      offset: (page - 1) * count
      limit: count
      order: order
      attributes:['id','last_comment_time','comment_count','visit_count']
      raw:false
    if condition then query.where = condition
    Topic.findAll(query)
    .success (articles)->
      callback null,articles
    .error (error)->
      callback error
  getById:(id,callback)->
    Topic.find
      where:
        id:id
      raw:true
      include:[User,Tag]
      
    .success (topic)->
      if not topic then callback new Error '不存在的话题'
      else
        callback null,topic
    .error (e)->
      callback e
  getAll:(page,count,condition,order,include,callback)->
    if arguments.length == 4
      callback = order
      order = null
      include = null
    else if arguments.length == 5
      callback = include
      include = null
    query = 
      offset: (page - 1) * count
      limit: count
      order: order || "id desc"
      include:[Tag]
      raw:true
    if condition then query.where = condition
    Topic.findAll(query)
    .success (ms)->
      callback null,ms
    .error (e)->
      callback e
  addZan:(topic_id,user_id,score,callback)->
    score = score*1
    TopicZanLogs.find
      where:
        topic_id:topic_id
        user_id:user_id
    .success (log)->
      if log then callback new  Error '已经赞过这个话题了哦'
      else
        Topic.find
          where:
            id:topic_id
        .success (topic)->
          if not topic then callback new  Error '不存在的话题'
          else
            TopicZanLogs.create({
              topic_id:topic_id
              user_id:user_id
            }).success (log)->
              topic.updateAttributes
                zan_count:topic.zan_count*1+1
              callback null,log,topic
            .error (e)->
              callback e
        .error (e)->
          callback e
    .error (e)->
      callback e
  getZansByTopicId:(topic_id,callback)->
    TopicZanLogs.findAll
      where:
        topic_id:topic_id
      include:[User]
      order:"id desc"
      raw:true
    .success (logs)->
      callback null,logs
    .error (e)->
      callback e
__FC func_topic,Topic,['add','delete','update',"count","addCount"]
module.exports = func_topic