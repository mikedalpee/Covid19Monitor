module Watir

  module ConvenienceMethods

    WRAPPABLE =
        [
            :first_match,
            :every_match,
            :match_id,
            :set_and_enter,
            :force_click,
            :force_set,
            :force_submit,
            :get_element,
            :get_elements,
            :first_descendant_match,
            :every_descenant_match
        ]

    def wrap(obj,method)
      wrapper = Module.new do
        WRAPPABLE.each do |m|
          define_method(m) do |*args|
            value = super *args
            if value.is_a?(Watir::Browser) || value.is_a?(Watir::Element)
              value.wrap(obj,method)
              return value
            elsif value.is_a?(Watir::ElementCollection)
              value.each do |e|
                e.wrap(obj,method)
              end
              return value
            end
            if !value && obj.send(method)
              value = super *args
            end
            value
          end
        end
      end
      self.extend(wrapper)
    end

    def wait_until_xpath_exists(xpath)
      Watir::Wait.until{self.element(xpath: "#{xpath}").exists?}
    end

    def wait_until_id_exists(id)
      Watir::Wait.until{self.element(id: "#{id}").exists?}
    end

    def call_by_type_xpath(type,xpath)
      if type.nil?
        self.element(xpath: xpath)
      else
        self.send type,xpath: xpath
      end
    end

    def call_by_type_id(type,id)
      if type.nil?
        self.element(id: id)
      else
        self.send type,id: id
      end
    end

    def first_match(xpath,options={})
      begin
        return nil if self.is_a?(Watir::Element) && !self.exists?

        xpath = "(//#{xpath})[1]"

        if options[:wait_until_exists]
          self.wait_until_xpath_exists(xpath)
        end

        (result = self.call_by_type_xpath(options[:type],xpath)).exists? ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def every_match(xpath,options={})
      begin
        return nil if self.is_a?(Watir::Element) && !self.exists?

        xpath = "//#{xpath}"

        if options[:wait_until_exists]
          self.wait_until_xpath_exists(xpath)
        end

        (result = self.elements(:xpath,xpath)).length > 0 ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def match_id(id,options={})
      begin
        return nil if self.is_a?(Watir::Element) && !self.exists?

        if options[:wait_until_exists]
          self.wait_until_id_exists(id)
        end

        (result = self.call_by_type_id(options[:type],id)).exists? ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def first_descendant_match(xpath)
      begin
        return nil if self.is_a?(Watir::Element) && !self.exists?

        (result = self.element(:xpath,"(descendant::#{xpath})[1]")).exists? ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def every_descendant_match(xpath)
      begin
        return nil if self.is_a?(Watir::Element) && !self.exists?

        (result = self.elements(:xpath,"descendant::#{xpath}")).length > 0 ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def my_parent
      begin
        #self.element(:xpath,"parent::node()")
        return nil if self.is_a?(Watir::Element) && !self.exists?

        (result = self.parent).exists? ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def my_siblings
      begin
        #result1 = self.element(:xpath,"(self::node())")
        #result2 = self.elements(:xpath,"(following-siblings::node())")
        #result = result1 << result2
        return nil if self.is_a?(Watir::Element) && !self.exists?

        (result = self.siblings).length > 0 ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def my_first_following_sibling
      begin
        #self.element(:xpath,"(following-sibling::node())[1]")
        return nil if self.is_a?(Watir::Element) && !self.exists?

        (result = self.following_sibling).exists? ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def my_following_siblings
      begin
        #result = self.elements(:xpath, "following-sibling::node()")
        return nil if self.is_a?(Watir::Element) && !self.exists?

        (result = self.following_siblings).length > 0 ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def my_first_preceding_sibling
      begin
        #self.element(:xpath,"(preceding-sibling::node())[1]")
        return nil if self.is_a?(Watir::Element) && !self.exists?

        (result = self.preceding_sibling).exists? ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def my_preceding_siblings
      begin
        #result = self.elements(:xpath, "preceding-sibling::node()")
        return nil if self.is_a?(Watir::Element) && !self.exists?

        (result = self.preceding_siblings).length > 0 ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def my_first_child
      begin
        #self.element(:xpath,"(child::node())[1]")
        return nil if self.is_a?(Watir::Element) && !self.exists?

        (result = self.child).exists? ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def my_children
      begin
        #result = self.elements(:xpath, "child::node()")
        return nil if self.is_a?(Watir::Element) && !self.exists?

        (result = self.children).length > 0 ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def my_first_descendant
      begin
        return nil if self.is_a?(Watir::Element) && !self.exists?

        (result = self.element(:xpath,"(descendant::node())[1]")).exists? ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def my_descendants
      begin
        return nil if self.is_a?(Watir::Element) && !self.exists?

        (result = self.elements(:xpath, "descendant::node()")).length > 0 ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def my_first_ancestor
      begin
        return nil if self.is_a?(Watir::Element) && !self.exists?

        (result = self.element(:xpath,"(ancestor::node())[1]")).exists? ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def my_ancestors
      begin
        return nil if self.is_a?(Watir::Element) && !self.exists?

        (result = self.elements(:xpath, "ancestor::node()")).length > 0 ?
            result :
            nil
      rescue => e
        nil
      end
    end

    def terminated?(options={})
      if options[:wait_until_exists]
        Watir::Wait.until{self.exists?}
      else
        self.exists?
      end
    end

    def my_attribute(name)
      begin
        self.exists? ?
            self.attribute_value(name) :
            nil
      rescue => e
        nil
      end
    end

    def my_class_list
      self.my_attribute('class')&.split
    end

    def my_tag
      begin
        self.exists? ?
            self.tag_name :
            nil
      rescue => e
        nil
      end
    end

    def my_text
      begin
        #   self.exists? ?
        #       ((result = self.text).blank? ?
        #            self.inner_text :
        #            result) :
        #       nil
        self.inner_text
      rescue => e
        nil
      end
    end

    def execute_javascript(js,options={})
      if options[:wait_until_exists]
        Watir::Wait.until{self.execute_script(js)}
      else
        self.execute_script(js)
      end
    end

    def self.selector_function(selector, options={})
      if options[:selector] == :id
        %Q|document.getElementById("#{selector}")|
      else
        %Q|document.evaluate("#{selector}",document,null,XPathResult.FIRST_ORDERED_NODE_TYPE,null).singleNodeValue|
      end
    end

    def get_element(selector,options={})
      begin
        if options[:wait_until_exists]
          self.element(xpath: selector).wait_until(&:exists?)
        else
          self.element(xpath: selector)
        end
      rescue => e
        nil
      end
    end

    def get_elements(selector,options={})
      begin
        if options[:wait_until_exists]
          self.element(xpath: selector).wait_until(&:exists?)
        end
        self.elements(xpath: selector)
      rescue => e
        nil
      end
    end

    def quick_set_and_enter(value)
      element.send_keys value, :enter
      self
    end

    def set_and_enter(selector,value,options)
      element = self.get_element(selector,options)
      if element.present? && element.exists?
        element.send_keys value, :enter
        return true
      end
      return false;
    end

    def quick_click
      self.execute_script("arguments[0].click();return true",self)
      self
    end

    def force_click(selector,options={})
      begin
        js =
            %Q|
          var e = #{ConvenienceMethods.selector_function(selector, options)};
          if (e)
          {
            e.click();
            return true;
          }
          return false;
          |
        execute_javascript(js,options)
      rescue => e
        false
      end
    end

    def quick_set(value)
      self.execute_script(%Q|arguments[0].value="#{value}";return true;|,self)
      true
    end

    def force_set(selector,value,options={})
      begin
        js =
            %Q|
          var e = #{ConvenienceMethods.selector_function(selector, options)};
          if (e)
          {
              e.value="#{value}";
              return true;
          }
          return false;
          |
        execute_javascript(js,options)
      rescue => e
        false
      end
    end

    def quick_submit
      self.execute_script("arguments[0].submit();return true;",self)
      self
    end

    def force_submit(selector,options={})
      begin
        js =
            %Q|
          var e = #{ConvenienceMethods.selector_function(selector, options)};
          if (e)
          {
              e.submit();
              return true;
          }
          return false;
          |
        execute_javascript(js,options)
      rescue => e
        false
      end
    end

    def generate_id
      begin
        js =
            %Q#
        var v =
          'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(
            /[xy]/g,
            function(c) {
              var r = Math.random()*16|0,
                  v = c == 'x' ? r : (r&0x3|0x8),
                  s = v.toString(16);
              return s;
            });
        return v;
        #
        self.execute_script(js)
      rescue => e
        ""
      end
    end

    def set_cookie(cookie,value,ttl)
      begin
        js =
            %Q|
          var date = new Date();
          date.setTime(date.getTime() + (#{ttl} * 60 * 1000));
          var cookie = "#{cookie}=" + escape("#{value}") + "; expires=" + date.toGMTString() + "; path=/";
          document.cookie = cookie;
          return true;
          |
        self.execute_script(js)
      rescue => e
        false
      end
    end

    def get_cookie(cookie)
      begin
        js =
            %Q|
          var i, c;
          var nameEQ = "#{cookie}=";
          var ca = document.cookie.split(';');
          for (i = 0; i < ca.length; i++) {
            c = ca[i];
            console.trace("c="+c);
            while (c.charAt(0) === ' ') {
              c = c.substring(1, c.length);
            }
            if (c.indexOf(nameEQ) === 0) {
              return unescape(c.substring(nameEQ.length, c.length));
            }
          }
          return null;
          |
        self.execute_script(js)
      rescue => e
        null
      end
    end

    def adjust_cookies

    end

    def empty_document?
      head = self.head.wait_until(&:exists?)
      body = self.body.wait_until(&:exists?)
      !head.child.exists? && !body.child.exists?
    end

    def simple_url(url)
      url.gsub(/[\/]+$/,'')
    end

  end

  class Browser
    include ConvenienceMethods
  end

  class Element
    include ConvenienceMethods
  end
end
