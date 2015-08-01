module ArticlesHelper
  def order_articles_by_stock
    parameters = {}
    q = params[:q]
    parameters[:q] = q if q
    parameters[:order] = if (_order = params[:order]) && _order[:stock] == 'desc'
                           { stock: :asc }
                         else
                           { stock: :desc }
                         end


    link_to(
      Article.human_attribute_name('stock'),
      articles_path(parameters)
    )
  end
end
