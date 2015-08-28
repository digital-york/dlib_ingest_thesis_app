class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :rememberable, :trackable

  before_save :get_ldap_email
  def get_ldap_email
    self.email = Devise::LDAP::Adapter.get_ldap_param(self.login, "mail").first
  end

  before_save :get_ldap_surname
  def get_ldap_surname
    self.surname = Devise::LDAP::Adapter.get_ldap_param(self.login, "sn").first
  end

  before_save :get_ldap_given_name
  def get_ldap_given_name
    self.givenname = Devise::LDAP::Adapter.get_ldap_param(self.login, "givenName").first
  end

  before_save :get_department
  def get_department
    #isMemberOf: cn=tg,ou=pgrad,ou=main,ou=ymgtsch,ou=students,ou=inst,ou=groups,dc=york,dc=ac,dc=uk
    #memberinfo = Devise::LDAP::Adapter.get_ldap_param(self.login, "isMemberOf").first
    memberinfo = Devise::LDAP::Adapter.get_ldap_param('brg506', "isMemberOf").first
    self.department = getDepartment(memberinfo)
  end

  def get_department_code
    memberinfo = Devise::LDAP::Adapter.get_ldap_param(self.login, "isMemberOf").first
    #memberinfo = Devise::LDAP::Adapter.get_ldap_param('ww721', "isMemberOf").first
    self.department = getDepartmentCode(memberinfo)
  end

  private
  def getDepartment(isMemberOfStr)
    department = ''
    # The format of isMemberOfStr is: 'cn=tg,ou=pgrad,ou=main,ou=ymgtsch,ou=students,ou=inst,ou=groups,dc=york,dc=ac,dc=uk'
    index = isMemberOfStr.index('ou=main,ou=') + 'ou=main,ou='.length

    departmentcode = isMemberOfStr[index..-1].partition(',').first
    #department = Settings.thesis.ldap.department.educat
    if !Settings.thesis.ldap.department[departmentcode].nil?
      department = Settings.thesis.ldap.department[departmentcode]
    end

    # if isMemberOfStr == 'cn=tg,ou=pgrad,ou=main,ou=ymgtsch,ou=students,ou=inst,ou=groups,dc=york,dc=ac,dc=uk'
    #   department = 'University of York. York Management School'
    # end
  end

  private
  def getDepartmentCode(isMemberOfStr)
    department = ''
    # The format of isMemberOfStr is: 'cn=tg,ou=pgrad,ou=main,ou=ymgtsch,ou=students,ou=inst,ou=groups,dc=york,dc=ac,dc=uk'
    # ["cn=support,ou=main,ou=libarch,ou=staff,ou=inst,ou=groups,dc=york,dc=ac,dc=uk"]
    #departmentcode = isMemberOfStr.partition('ou=main,ou=').first.partition(',').first
    #JA: this seems to get the right attribute for libarchstaff, not sure that will work across the board
    isMemberOfStr.partition('ou=main,ou=').third.partition(',').first

  end
end
