/**
 */
package dk.sdu.mmmi.embedix.ulswig;

import org.eclipse.emf.common.util.EList;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Grouping</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * <ul>
 *   <li>{@link dk.sdu.mmmi.embedix.ulswig.Grouping#getName <em>Name</em>}</li>
 *   <li>{@link dk.sdu.mmmi.embedix.ulswig.Grouping#getElements <em>Elements</em>}</li>
 * </ul>
 * </p>
 *
 * @see dk.sdu.mmmi.embedix.ulswig.UlswigPackage#getGrouping()
 * @model
 * @generated
 */
public interface Grouping extends Member
{
  /**
   * Returns the value of the '<em><b>Name</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <p>
   * If the meaning of the '<em>Name</em>' attribute isn't clear,
   * there really should be more of a description here...
   * </p>
   * <!-- end-user-doc -->
   * @return the value of the '<em>Name</em>' attribute.
   * @see #setName(String)
   * @see dk.sdu.mmmi.embedix.ulswig.UlswigPackage#getGrouping_Name()
   * @model
   * @generated
   */
  String getName();

  /**
   * Sets the value of the '{@link dk.sdu.mmmi.embedix.ulswig.Grouping#getName <em>Name</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Name</em>' attribute.
   * @see #getName()
   * @generated
   */
  void setName(String value);

  /**
   * Returns the value of the '<em><b>Elements</b></em>' containment reference list.
   * The list contents are of type {@link dk.sdu.mmmi.embedix.ulswig.GroupElement}.
   * <!-- begin-user-doc -->
   * <p>
   * If the meaning of the '<em>Elements</em>' containment reference list isn't clear,
   * there really should be more of a description here...
   * </p>
   * <!-- end-user-doc -->
   * @return the value of the '<em>Elements</em>' containment reference list.
   * @see dk.sdu.mmmi.embedix.ulswig.UlswigPackage#getGrouping_Elements()
   * @model containment="true"
   * @generated
   */
  EList<GroupElement> getElements();

} // Grouping
