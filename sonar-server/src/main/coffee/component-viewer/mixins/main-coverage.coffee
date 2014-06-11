define [], () ->

  $ = jQuery
  API_COVERAGE = "#{baseUrl}/api/coverage/show"
  LINES_AROUND_COVERED_LINE = 1


  class CoverageMixin

    requestCoverage: (key, type = 'UT') ->
      $.get API_COVERAGE, key: key, type: type, (data) =>
        return unless data?.coverage?
        @state.set 'hasCoverage', true
        @source.set coverage: data.coverage
        @augmentWithCoverage data.coverage


    augmentWithCoverage: (coverage) ->
      formattedSource = @source.get 'formattedSource'
      coverage.forEach (c) ->
        line = _.findWhere formattedSource, lineNumber: c[0]
        line.coverage =
          covered: c[1]
          testCases: c[2]
          branches: c[3]
          coveredBranches: c[4]
        if line.coverage.branches? && line.coverage.coveredBranches?
          line.coverage.branchCoverageStatus = 'green' if line.coverage.branches == line.coverage.coveredBranches
          line.coverage.branchCoverageStatus = 'orange' if line.coverage.branches > line.coverage.coveredBranches
          line.coverage.branchCoverageStatus = 'red' if line.coverage.coveredBranches == 0
      @source.set 'formattedSource', formattedSource


    showCoverage: (store = false) ->
      @settings.set 'coverage', true
      @storeSettings() if store
      unless @state.get 'hasCoverage'
        @requestCoverage(@key).done => @sourceView.render()
      else
        @sourceView.render()


    hideCoverage: (store = false) ->
      @settings.set 'coverage', false
      @storeSettings() if store
      @sourceView.render()


    filterByCoverage: (predicate) ->
      @requestCoverage(@key).done => @_filterByCoverage(predicate)


    filterByCoverageIT: (predicate) ->
      @requestCoverage(@key, 'IT').done => @_filterByCoverage(predicate)


    _filterByCoverage: (predicate) ->
      period = @state.get('period')
      if period
        periodDate = period.get 'sinceDate'
        p = predicate
        predicate = (line) =>
          line?.scm?.date? && (new Date(line.scm.date) >= periodDate) && p(line)

      formattedSource = @source.get 'formattedSource'
      @settings.set 'coverage', true
      @sourceView.resetShowBlocks()
      formattedSource.forEach (line) =>
        if predicate line
          ln = line.lineNumber
          @sourceView.addShowBlock ln - LINES_AROUND_COVERED_LINE, ln + LINES_AROUND_COVERED_LINE
      @sourceView.render()


    # Unit Tests
    filterByLinesToCover: ->
      @filterByCoverage (line) -> line?.coverage?.covered?


    filterByUncoveredLines: ->
      @filterByCoverage (line) -> line?.coverage?.covered? && !line.coverage.covered


    filterByBranchesToCover: ->
      @filterByCoverage (line) -> line?.coverage?.branches?


    filterByUncoveredBranches: ->
      @filterByCoverage (line) -> line?.coverage?.branches? && line.coverage.coveredBranches? &&
          line.coverage.branches > line.coverage.coveredBranches


    # Integration Tests
    filterByLinesToCoverIT: ->
      @filterByCoverageIT (line) -> line?.coverage?.covered?


    filterByUncoveredLinesIT: ->
      @filterByCoverageIT (line) -> line?.coverage?.covered? && !line.coverage.covered


    filterByBranchesToCoverIT: ->
      @filterByCoverageIT (line) -> line?.coverage?.branches?


    filterByUncoveredBranchesIT: ->
      @filterByCoverageIT (line) -> line?.coverage?.branches? && line.coverage.coveredBranches? &&
          line.coverage.branches > line.coverage.coveredBranches