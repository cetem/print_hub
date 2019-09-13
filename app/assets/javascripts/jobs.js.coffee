@Jobs =
  jobs: {},
  pagesList: {},
  pricesList: {},
  oddPagesTypes: {},

  getDataFromPrintJobs: (attr)->
    JSON.parse(document.querySelector('.jobs-container').dataset[attr])

  getPrintableJobs: ->
    document.querySelectorAll('.js-printable-job:not(.exclude-from-total)')

  loadPricesData: ->
    Jobs.pricesList = Jobs.getDataFromPrintJobs('pricesList')
    Jobs.oddPagesTypes = Jobs.getDataFromPrintJobs('oddPagesTypes')

  assignDefaultOrGetJob: (job)->
    Jobs.jobs[job.id] ||= _.clone({
      copies: 1,
      oddPages: 0,
      evenPages: 0,
      rangePages: 0,
      pricePerCopy: 0.0,
      price: 0.0,
      printJobType: 1,
      stock: 0
    })
    Jobs.jobs[job.id]

  listenRangeChanges: ->
    $(document).on 'change blur', '.js-page-range', ->
      $element = $(this)
      parentElement = $element.parents('.js-printable-job')[0]
      elementValue = this.value
      [validRanges, maxPage, rangePages] = [true, null, 0]
      pages = parseInt(parentElement.querySelector('.js-job-pages').value || 0, 10)
      ranges = elementValue.trim().split(/\s*,\s*/).sort (r1, r2)->
        r1Value = parseInt(r1.match(/^\d+/), 10) || 0
        r2Value = parseInt(r2.match(/^\d+/), 10) || 0

        r1Value - r2Value

      _.each ranges, (r)->
        data = r.match /^(\d+)(-(\d+))?$/
        n1 = parseInt(data[1], 10) if data
        n2 = parseInt(data[3], 10) if data

        validRanges = validRanges && n1 && n1 > 0 && (!n2 || n1 < n2) && (!maxPage || maxPage < n1)

        maxPage = n2 || n1
        rangePages += if n2 then n2 + 1 - n1 else 1

      controlGroup = $element.parents('.control-group')

      if (/^\s*$/.test(elementValue) || validRanges) && (!pages || !maxPage || pages >= maxPage)
        controlGroup.removeClass('error')
        jobStorage = Jobs.assignDefaultOrGetJob(parentElement)

        if /^\s*$/.test(elementValue) && pages
          jobStorage.rangePages = pages
          Jobs.reCalcPages(parentElement)
        else if !/^\s*$/.test(elementValue) && validRanges
          jobStorage.rangePages = rangePages
          Jobs.reCalcPages(parentElement)
      else
        controlGroup.addClass('error')

  updatePricePerCopyForJob: (job)->
      jobStorage = Jobs.assignDefaultOrGetJob(job)
      jobType = parseInt(job.querySelector('.js-print_job_type-selector').value, 10)

      jobStorage.printJobType = jobType
      jobStorage.pricePerCopy = PriceChooser.choose(
        Jobs.pricesList[jobType],
        Jobs.pagesList[jobType] || 1
      )

  changeMoneyTitleAndBadge: (job)->
    jobStorage = Jobs.assignDefaultOrGetJob(job)
    jobPrice = (jobStorage.price || 0.0).toFixed(3)
    jobPricePerCopy = (jobStorage.pricePerCopy || 0.0).toFixed(3)
    money = job.querySelector('span.money')
    regEx = /(\d+\.\d+|NaN)$/

    money.setAttribute(
      'title',
      Util.replaceWithRegEx(money.getAttribute('title'), regEx, jobPricePerCopy)
    )
    money.innerHTML = Util.replaceWithRegEx(money.innerHTML.trim(), regEx, jobPrice)

  updateCopiesForJob: (job) ->
    jobStorage = Jobs.assignDefaultOrGetJob(job)

    jobStorage.printJobType = parseInt(
      job.querySelector('.js-print_job_type-selector').value,
      10
    )

    copies = parseInt(job.querySelector('.js-job-copies').value || 0, 10)
    rangePages = jobStorage.rangePages

    if rangePages == 0
      rangePages = parseInt(job.querySelector('.js-job-pages').value || 0, 10)
      jobStorage.rangePages = rangePages

    oddPages = rangePages % 2
    evenPages = rangePages - oddPages

    jobStorage.copies = copies
    jobStorage.oddPages = copies * oddPages
    jobStorage.evenPages = copies * evenPages

    Print.updateStock(job)

  updateGlobalCopies: ->
    pagesList = {}
    _.each Jobs.jobs, (jobStorage)->
      printJobType = jobStorage.printJobType
      oddPagesType = Jobs.oddPagesTypes[printJobType] || printJobType

      pagesList[oddPagesType] ||= 0
      pagesList[oddPagesType] += jobStorage.oddPages || 0
      pagesList[printJobType] ||= 0
      pagesList[printJobType] += jobStorage.evenPages || 0

    Jobs.pagesList = pagesList

  updatePriceForJob: (job)->
    # Has to run before others
    evenPagesPrice = Jobs.updatePricePerCopyForJob(job)

    jobStorage = Jobs.assignDefaultOrGetJob(job)
    jobType = jobStorage.printJobType
    oddPagesType = Jobs.oddPagesTypes[jobType] || jobType
    oddPages = jobStorage.oddPages
    evenPages = jobStorage.evenPages

    oddPagesPrice = PriceChooser.choose(
      parseFloat(Jobs.pricesList[oddPagesType]),
      Jobs.pagesList[oddPagesType] || 1
    )

    jobStorage.price = (
      evenPagesPrice * evenPages + oddPagesPrice * oddPages
    )

  updatePriceToAllJobs: ->
    _.each Jobs.getPrintableJobs(), (job) ->
      Jobs.updatePriceForJob(job)
      Jobs.changeMoneyTitleAndBadge(job)

  updateGlobalPrice: ->
    Jobs.globalPrice = _.reduce(
      _.values(Jobs.jobs),
      (memo, job)-> memo + job.price,
      0.0
    )

  updateTotalPrices: ->
    Print.updateTotalPrices()

  reCalcPrices: ->
    Jobs.updatePriceToAllJobs()
    Jobs.updateGlobalPrice()
    Print.updateTotalPrice()

  reCalcEverything: ->
    _.each Print.getPayableArticles(), (articleLine) ->
      Print.updateArticleLinePrice(articleLine)

    _.each Jobs.getPrintableJobs(), (job) ->
      Jobs.updateCopiesForJob(job)

    Jobs.updateGlobalCopies()
    Jobs.reCalcPrices()

  reCalcPages: (job)->
    oldPageList = _.clone(Jobs.pagesList)
    needToReCalcAll = false

    Jobs.updateCopiesForJob(job)
    Jobs.updateGlobalCopies()

    _.each Jobs.pageList, (pages, jobType) ->
      oldPages = oldPageList[jobType] || 0
      printJobPrice = Jobs.pricesList[jobType]

      if (
        PriceChooser.choose(printJobPrice, oldPages).toFixed(3) !=
          PriceChooser.choose(printJobPrice, pages).toFixed(3)
      )
        needToReCalcAll = true
        return

    if needToReCalcAll
      Jobs.updatePriceToAllJobs()
    else
      Jobs.updatePriceForJob(job)
      Jobs.changeMoneyTitleAndBadge(job)

    Jobs.updateGlobalPrice()
    Print.updateTotalPrice()








